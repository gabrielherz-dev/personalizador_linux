#!/bin/bash

#Instalación para manejo de btrfs
apt install -y btrfs-progs

# Se verifica si el usuario efectivo es superusuario
if [[ ! $EUID -eq 0 ]]; then
    echo "No se tienen permisos de superusuario. Ejecuta: sudo $0"
    exit 1
fi

# Nombre de usuario fijo para subvolúmenes en /home/
MAIN_USER="gherz"

# Verificar si el usuario existe antes de proceder
if ! id "$MAIN_USER" &>/dev/null; then
    echo "Error: El usuario '$MAIN_USER' no existe en este sistema."
    exit 1
fi

# Prefijo para los Ficheros de snapshots
PREFIJO_SNAP=".snapshots"

# --- Configuración de Btrfs y Opciones ---
# En Pop!_OS (systemd-boot), obtenemos el UUID directamente del punto de montaje raíz
ROOT_UUID=$(findmnt -no UUID /)

if [[ -z "$ROOT_UUID" ]]; then
    echo "Error: No se pudo determinar el UUID del sistema de archivos raíz."
    exit 1
fi

# Opciones de montaje (Ajustadas para SSD/NVMe comunes en Pop!_OS)
OPTIONS="defaults,noatime,compress=zstd:3"

# --- Definición de Directorios ---
# Usamos rutas absolutas para evitar confusiones
USER_HOME="/home/$MAIN_USER"

SUBVOLUMES=(
    "opt"
    "var/cache"
    "var/lib/gdm" # Pop!_OS usa GDM por defecto
    "var/log"
    "var/spool"
    "var/tmp"
    "var/www"
    "home/$MAIN_USER"
    "home/$MAIN_USER/.ssh"
    "home/$MAIN_USER/.gnupg"
    "home/$MAIN_USER/.local/share/flatpak"
    "home/$MAIN_USER/var/lib/flatpak"
)

# --- Creación de Directorios Base ---
echo "📂 Creando estructura de directorios..."
mkdir -vp "$USER_HOME/.ssh" "$USER_HOME/.gnupg" "$USER_HOME/.local/share/flatpak" \
          "$USER_HOME/var/lib/flatpak" "$USER_HOME/.mozilla" "$USER_HOME/www" \
          "/var/lib/gdm" "/var/www"

# --- Lógica de Snapshots ---
SUBVOLUMES_SNAP=()
for dir in "${SUBVOLUMES[@]}" ; do
    dir_snap="$dir/$PREFIJO_SNAP"
    SUBVOLUMES_SNAP+=( "${dir_snap}" )
    if [ ! -d "/$dir_snap" ] ; then
        mkdir -vp "/$dir_snap"
    fi
done

SUBVOLUMES_SNAP+=("${PREFIJO_SNAP}")
if [ ! -d "/${PREFIJO_SNAP}" ] ; then
    mkdir -vp "/${PREFIJO_SNAP}"
fi

# Unir listas
ALL_SUBVOLS=("${SUBVOLUMES[@]}" "${SUBVOLUMES_SNAP[@]}")

# --- CREACIÓN DE SUBVOLUMENES Y EDICIÓN DE FSTAB ---
MAX_LEN="$(printf '/%s\n' "${ALL_SUBVOLS[@]}" | wc -L)"

echo "🛠️  Generando subvolúmenes Btrfs..."

for dir in "${ALL_SUBVOLS[@]}" ; do
    if [[ -d "/${dir}" && ! -L "/${dir}" ]] ; then
        # Si el directorio existe y no es un subvolumen ya montado
        if ! btrfs subvolume show "/${dir}" &>/dev/null; then
            echo "Renombrando existente /${dir} a /${dir}-old"
            mv "/${dir}" "/${dir}-old"
            btrfs subvolume create "/${dir}"
            
            # Si había datos, los movemos al nuevo subvolumen
            if [ "$(ls -A "/${dir}-old")" ]; then
                echo "Copiando datos a /${dir}..."
                cp -ax "/${dir}-old/." "/${dir}/"
            fi
        fi
    else
        [ ! -d "/${dir}" ] && btrfs subvolume create "/${dir}"
    fi

    # Evitar duplicados en fstab
    if ! grep -q "subvol=${dir}," /etc/fstab; then
        printf "UUID=%-36s /%-25s btrfs   subvol=%-30s %-s 0 0\n" \
            "$ROOT_UUID" "$dir" "$dir" "$OPTIONS" >> /etc/fstab
    fi
done

# --- Permisos y Limpieza ---
echo "🔒 Ajustando permisos para $MAIN_USER..."
chown -R "$MAIN_USER:$MAIN_USER" "$USER_HOME"
chmod 0700 "$USER_HOME/.ssh" "$USER_HOME/.gnupg"

echo "🔄 Recargando systemd y montando..."
systemctl daemon-reload
mount -a

# --- Verificación Final ---
echo "🔍 Verificando montajes..."
ALL_OK=true
for dir in "${ALL_SUBVOLS[@]}"; do
    if findmnt "/$dir" > /dev/null; then
        echo "✅ /$dir montado correctamente."
    else
        echo "❌ /$dir NO se montó."
        ALL_OK=false
    fi
done

if [ "$ALL_OK" = true ]; then
    echo "🚀 Todo listo. Limpiando directorios -old..."
    for dir in "${ALL_SUBVOLS[@]}" ; do
        [ -d "/${dir}-old" ] && rm -rf "/${dir}-old"
    done
else
    echo "⚠️  Hubo errores en el montaje. Revisa /etc/fstab manualmente."
fi
