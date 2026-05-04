#!/bin/bash

# Se verifica si el usuario efectivo es superusuario
if [[ ! $EUID -eq 0 ]]; then
    echo "No se tienen permisos de superusuario, ejecutar el script desde el usuario principal y con los comandos sudo/su"
    exit 1
fi

# Nombre de usuario fijo para subvolúmenes en /home/
MAIN_USER="gherz"

# --- Configuración de Btrfs y Opciones ---
# Obtener el UUID del sistema Btrfs (dispositivo en /)
ROOT_UUID="$(/usr/sbin/grub-probe --target=fs_uuid /)"

# Opciones de montaje recomendadas (añadimos compresión para ahorrar espacio)
OPTIONS="defaults,noatime,compress=zstd:3"

# Listado de subvolúmenes a crear
SUBVOLUMES=(
    ".snapshots"
    "opt"
    "var/cache"
    "var/lib/sddm"
    "var/tmp"
    "var/log"
    "var/spool"
    "home/$MAIN_USER"
    "home/$MAIN_USER/.local/share/flatpak"
    "home/$MAIN_USER/var/lib/flatpak"
    "home/$MAIN_USER/.local/share/distrobox"
)

# --- CREACIÓN DE SUBVOLUMENES Y MODIFICACIÓN DE FSTAB ---

MAX_LEN="$(printf '/%s\n' "${SUBVOLUMES[@]}" | wc -L)"

for dir in "${SUBVOLUMES[@]}" ; do
    # PASO CRÍTICO: Asegurar que el directorio padre existe antes de crear el subvolumen
    parent_dir=$(dirname "/$dir")
    if [ ! -d "$parent_dir" ]; then
        echo "Creando directorio padre: $parent_dir"
        mkdir -p "$parent_dir"
    fi

    if [[ -d "/${dir}" && ! -L "/${dir}" ]] ; then
        echo "Renombrando directorio existente /${dir} a /${dir}-old"
        mv -v "/${dir}" "/${dir}-old"
        btrfs subvolume create "/${dir}"
        echo "Copiando datos de /${dir}-old a /${dir}"
        cp -ar "/${dir}-old/." "/${dir}/"
    else
        echo "Creando subvolumen /${dir}"
        btrfs subvolume create "/${dir}"
    fi

    # Generación de la entrada para /etc/fstab si no existe ya
    if ! grep -q " /${dir} " /etc/fstab; then
        printf "UUID=%-41s /%-25s btrfs   subvol=%-25s %s 0 0\n" \
            "${ROOT_UUID}" "${dir}" "${dir}" "${OPTIONS}" | \
            tee -a /etc/fstab
    fi
done

# Corregir permisos de home
echo "Corrigiendo permisos para $MAIN_USER..."
chown -R $MAIN_USER:$MAIN_USER "/home/$MAIN_USER"
# Asegurar permisos estrictos en carpetas sensibles si existen
[ -d "/home/$MAIN_USER/.ssh" ] && chmod 700 "/home/$MAIN_USER/.ssh"
[ -d "/home/$MAIN_USER/.gnupg" ] && chmod 700 "/home/$MAIN_USER/.gnupg"

# Recargar /etc/fstab y montar los subvolúmenes.
echo "Recargando demonios del sistema y montando subvolúmenes..."
systemctl daemon-reload
mount -va

echo "========================================="
echo "✅ Verificación de Subvolúmenes"
echo "========================================="

ALL_OK=true
for SUBVOLUME in "${SUBVOLUMES[@]}"; do
    MOUNT_INFO=$(findmnt -n -T "/$SUBVOLUME" -o FSTYPE)
    if [[ "$MOUNT_INFO" == "btrfs" ]]; then
        echo "✅ /$SUBVOLUME OK"
    else
        echo "❌ /$SUBVOLUME FALLÓ"
        ALL_OK=false
    fi
done

if [ "$ALL_OK" = true ]; then
    # Borrar antiguos si todo salió bien
    for dir in "${SUBVOLUMES[@]}" ; do
        if [[ -d "/${dir}-old" ]] ; then
            echo "Borrando respaldo temporal /${dir}-old"
            rm -rf "/${dir}-old"
        fi
    done
    echo "¡Listo! Todos los subvolúmenes están activos y limpios."
else
    echo "Revisa los errores arriba antes de borrar los directorios -old manualmente."
fi
