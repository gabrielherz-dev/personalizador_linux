#!/bin/bash

# Se verifica si el usuario efectivo es superusuario
if [[ ! $EUID -eq 0 ]]; then
    echo "No se tienen permisos de superusuario, ejecutar el script desde el usuario principal y con los comandos sudo/su"
    exit 1
fi

# Nombre de usuario fijo para subvolúmenes en /home/
MAIN_USER="gherz"

# Prefijo para los Ficheros de snapshots
PREFIJO_SNAP=".snapshots"

# --- Creación de directorios necesarios (usando MAIN_USER) ---
# Se utiliza -p para crear directorios padres si no existen
DIR_SSH="/home/$MAIN_USER/.ssh"
DIR_GNUPG="/home/$MAIN_USER/.gnupg"
DIR_FLATP_CONF="/home/$MAIN_USER/.local/share/flatpak"
DIR_FLAT="/home/$MAIN_USER/var/lib/flatpak"
DIR_MOZILLA="/home/$MAIN_USER/.mozilla"
DIR_WWW="/home/$MAIN_USER/www"
DIR_LISGHTDM="/var/lib/lightdm"
DIR_GDM="/var/lib/gdm"

# Creación de directorios
mkdir -vp "$DIR_SSH" "$DIR_GNUPG" "$DIR_FLATP_CONF" "$DIR_FLAT" "$DIR_MOZILLA" "$DIR_WWW" "$DIR_LISGHTDM" "$DIR_GDM"

# --- Configuración de Btrfs y Opciones ---
# Obtener el UUID del sistema Btrfs (dispositivo en /)
ROOT_UUID="$(/usr/sbin/grub-probe --target=fs_uuid /)"

# Opciones de montaje
OPTIONS="defaults"

# Listado de subvolúmenes a crear (usando MAIN_USER)
SUBVOLUMES=(
    "opt"
    "var/cache"
    "var/lib/lightdm"
    "var/lib/gdm"
    #"var/lib/libvirt/images"
    "var/log"
    "var/spool"
    "var/tmp"
    "var/www"
    "home/$MAIN_USER/.mozilla"
    "home/$MAIN_USER/.ssh"
    "home/$MAIN_USER/.gnupg"
    "home/$MAIN_USER/.local/share/flatpak"
    "home/$MAIN_USER/var/lib/flatpak"
)

# --- CREACIÓN DE SUBVOLUMENES DE SNAPSHOTS ---

# Creamos la lista de subvolúmenes para snapshots (nombre/del/subvolumen/.snapshots)
SUBVOLUMES_SNAP=()

# Primero, los .snapshots de cada subvolumen
for dir in "${SUBVOLUMES[@]}" ; do
    dir_snap="$dir/$PREFIJO_SNAP"
    SUBVOLUMES_SNAP+=( "${dir_snap}" )
    # Crear los directorios .snapshots para que puedan luego montarse
    if [ ! -d "/$dir_snap" ] ; then
        mkdir -vp "/$dir_snap"
    fi
done

# Agregamos el directorio .snapshots al raíz
SUBVOLUMES_SNAP+=("${PREFIJO_SNAP}")
if [ ! -d "/${PREFIJO_SNAP}" ] ; then
    mkdir -vp "/${PREFIJO_SNAP}"
fi

# Se agregan los subvolúmenes de .snapshots a la lista principal de subvolúmenes a crear
SUBVOLUMES+=("${SUBVOLUMES_SNAP[@]}")

# --- CREACIÓN DE SUBVOLUMENES Y MODIFICACIÓN DE FSTAB ---

MAX_LEN="$(printf '/%s\n' "${SUBVOLUMES[@]}" | wc -L)"

for dir in "${SUBVOLUMES[@]}" ; do
    if [[ -d "/${dir}" ]] ; then
        echo "Renombrando directorio existente /${dir} a /${dir}-old"
        mv -v "/${dir}" "/${dir}-old"
        btrfs subvolume create "/${dir}"
        echo "Copiando datos de /${dir}-old a /${dir}"
        # Aseguramos que la copia use punto al final del origen para copiar contenidos
        cp -ar "/${dir}-old/." "/${dir}/"
    else
        echo "Creando subvolumen /${dir}"
        btrfs subvolume create "/${dir}"
    fi

    # Generación de la entrada para /etc/fstab, usando la opción 'subvol=' directa
    printf "%-41s %-${MAX_LEN}s %-5s %-s %-s\n" \
        "UUID=${ROOT_UUID}" \
        "/${dir}" \
        "btrfs" \
        "subvol=${dir},${OPTIONS}" \
        "0 0" | \
        tee -a /etc/fstab
done

# Corregir permisos de home (usando MAIN_USER)
chown -cR $MAIN_USER:$MAIN_USER /home/$MAIN_USER/
chmod -vR 0700 /home/$MAIN_USER/{.gnupg,.ssh}

# Recargar /etc/fstab y montar los subvolúmenes.
echo "Recargando demonios del sistema y montando subvolúmenes..."
systemctl daemon-reload
mount -va

---

## ✅ Verificación de Subvolúmenes

##### INI - Verificar si han sido creados los volumenes
# Buscar dispositivos Btrfs en el sistema
BTRFS_DEVICES=($(findmnt -t btrfs -n -o SOURCE | sort -u))

if [[ ${#BTRFS_DEVICES[@]} -eq 0 ]]; then
    echo "❌ No se encontraron dispositivos Btrfs montados."
    exit 1
fi

echo "📂 Dispositivos Btrfs detectados: ${BTRFS_DEVICES[*]}"

# Verificar cada subvolumen
echo "🔍 Verificando subvolúmenes..."
MISSING_SUBVOLUMES=()
ALL_OK=true

for SUBVOLUME in "${SUBVOLUMES[@]}"; do
    # Usamos -R para encontrar el punto de montaje real si el subvolumen es una ruta relativa
    MOUNT_INFO=$(findmnt -R -n -T "/$SUBVOLUME" -o SOURCE,FSTYPE)

    if [[ -z "$MOUNT_INFO" ]]; then
        echo "⚠️  Falta el subvolumen: /$SUBVOLUME"
        MISSING_SUBVOLUMES+=("$SUBVOLUME")
        ALL_OK=false
        continue
    fi

    DEVICE=$(echo "$MOUNT_INFO" | awk '{print $1}')
    FSTYPE=$(echo "$MOUNT_INFO" | awk '{print $2}')

    if [[ "$FSTYPE" == "btrfs" ]]; then
        echo "✅ $SUBVOLUME está en $DEVICE Btrfs"
    else
        echo "❌ $SUBVOLUME no está en un sistema de archivos Btrfs  $FSTYPE "
        MISSING_SUBVOLUMES+=("$SUBVOLUME")
        ALL_OK=false
    fi
done

if [[ "$ALL_OK" == "false" ]]; then
    echo "⚠️  Se encontraron subvolúmenes faltantes o incorrectamente montados."
else
    echo "✅ Todos los subvolúmenes están correctamente montados en Btrfs."
fi

# Se borran los volúmenes antiguos
for dir in "${SUBVOLUMES[@]}" ; do
    if [[ -d "/${dir}-old" ]] ; then
        echo "Borrando directorio antiguo /${dir}-old"
        rm -rvf "/${dir}-old"
    fi
done

##### FIN - Verificar si han sido creados los volumenes
