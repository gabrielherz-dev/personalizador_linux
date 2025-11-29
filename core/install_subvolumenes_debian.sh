#!/bin/bash

# Se verifica si el usuario efectivo es superusuario
if [[ ! $EUID -eq 0 ]]; then
	echo "No se tienen permisos de superusuario, ejecutar el script desde el usuario principal y con los comandos sudo/su"
	exit 1
fi
# Prefijo para los Ficheros de snapshots
PREFIJO_SNAP=".snapshots"

# Creo los directorios necesarios si no existen
DIR_SSH="/home/$USER/.ssh"
DIR_GNUPG="/home/$USER/.gnupg"
DIR_FLATP_CONF="/home/$USER/.local/share/flatpak"
DIR_FLAT="/home/$USER/var/lib/flatpak"
DIR_MOZILLA="/home/$USER/.mozilla"
DIR_WWW="home/$USER/www"
DIR_LISGHTDM="/var/liv/lightdm"
DIR_GDM="/var/liv/gdm"


if [ ! -d "$DIR_SSH" ]; then
    mkdir -vp "$DIR_SSH"
fi
if [ ! -d "$DIR_GNUPG" ]; then
    mkdir -vp "$DIR_GNUPG"
fi
if [ ! -d "$DIR_FLATP_CONF" ]; then
    mkdir -vp "$DIR_FLATP_CONF"
fi
if [ ! -d "$DIR_FLAT" ]; then
    mkdir -vp "$DIR_FLAT"
fi
if [ ! -d "$DIR_MOZILLA" ]; then
    mkdir -vp "$DIR_MOZILLA"
fi
if [ ! -d "$DIR_WWW" ]; then
    mkdir -vp "$DIR_WWW"
fi
if [ ! -d "$DIR_LISGHTDM" ]; then
    mkdir -vp "$DIR_LISGHTDM"
fi
if [ ! -d "$DIR_GDM" ]; then
    mkdir -vp "$DIR_GDM"
fi


# Get the UUID of your btrfs system root.
ROOT_UUID="$(/usr/sbin/grub-probe --target=fs_uuid /)"
# Get the btrfs subvolume mount options from the /etc/fstab file.
#OPTIONS="$(grep '/home' /etc/fstab \
#    | awk '{print $4}' \
#    | cut -d, -f2-)"
OPTIONS="defaults"

# Listado de subvolúmen es a crear
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
    "home/$USER/.mozilla"
    "home/$USER/.ssh"
    "home/$USER/.gnupg"
    "home/$USER/.local/share/flatpak"
    "home/$USER/var/lib/flatpak"
)

# Crear Directories para snapshots y creación de subvolúmenes
SUBVOLUMES_SNAP=()
for dir in "${SUBVOLUMES[@]}" ; do
        if [[ -d "/${dir}" ]] ; then
		SUBVOLUMES_SNAP+=( "${dir}/${PREFIJO_SNAP}" )
        fi
done
#Se agrega el directorio .snapshots al raíz
SUBVOLUMES_SNAP+=("${PREFIJO_SNAP}")
# Se agregan los subvolumenes de .snapshots a los subvolúmenes principal
SUBVOLUMES+=("${SUBVOLUMES_SNAP[@]}")
e


# Crear Directories para snapshots y creación de subvolúmenes
SUBVOLUMES_SNAP=()
for dir in "${SUBVOLUMES[@]}" ; do
	dir_snap=""
        if [[ -d "/${dir}" ]] ; then
		dir_snap="$dir/$PREFIJO_SNAP" 
		SUBVOLUMES_SNAP+=( "${dir_snap}" )
        fi
	# Se crean los directorios .snapshots para que puedan luego montarse en /etc/fstab
	if [ ! -d "${dir_snap}" ] ; then
		mkdir -vp "/$dir_snap"
	fi
done
#
# Se agregan los subvolumenes de .snapshots a los subvolúmenes principal
SUBVOLUMES+=("${SUBVOLUMES_SAP[@]}")

MAX_LEN="$(printf '/%s\n' "${SUBVOLUMES[@]}" | wc -L)"

# Obtener nombre del subvolumen raíz actual
ROOTFS_SUBVOL_NAME=$(findmnt -t btrfs -n -o SOURCE | awk -F '[\@\]]' '{print$2}')

for dir in "${SUBVOLUMES[@]}" ; do
    if [[ -d "/${dir}" ]] ; then
        mv -v "/${dir}" "/${dir}-old"
        btrfs subvolume create "/${dir}"
        cp -ar "/${dir}-old/." "/${dir}/"
     else
        btrfs subvolume create "/${dir}"
    fi
    #ROOTFS_SUBVOL_NAME=$(findmnt -t btrfs -n -o SOURCE | awk -F '[\@\]]' '{print$2}')
    #/sbin/restorecon -RF "/${dir}"
    printf "%-41s %-${MAX_LEN}s %-5s %-s %-s\n" \
        "UUID=${ROOT_UUID}" \
        "/${dir}" \
        "btrfs" \
        "subvol=@$ROOTFS_SUBVOL_NAME/${dir},${OPTIONS}" \
        "0 0" | \
        tee -a /etc/fstab
done

chown -cR $USER:$USER /home/$USER/
chmod -vR 0700 /home/$USER/{.gnupg,.ssh}

# Reload /etc/fstab to mount all the subvolumes.
systemctl daemon-reload
mount -va

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

for SUBVOLUME in "${SUBVOLUMES[@]}"; do
    # Buscar si el subvolumen está montado en un dispositivo Btrfs
    #MOUNT_INFO=$(findmnt -n -T "$SUBVOLUME" -o SOURCE,FSTYPE)
    MOUNT_INFO=$(findmnt -n -T "/$SUBVOLUME" -o SOURCE,FSTYPE)

    if [[ -z "$MOUNT_INFO" ]]; then
        echo "⚠️  Falta el subvolumen: /$SUBVOLUME"
        MISSING_SUBVOLUMES+=("$SUBVOLUME")
        continue
    fi

    DEVICE=$(echo "$MOUNT_INFO" | awk '{print $1}')
    FSTYPE=$(echo "$MOUNT_INFO" | awk '{print $2}')

    # Verificar si el subvolumen pertenece a un dispositivo Btrfs
    if [[ "$FSTYPE" == "btrfs" ]]; then
        echo "✅ $SUBVOLUME está en $DEVICE Btrfs"
    else
        echo "❌ $SUBVOLUME no está en un sistema de archivos Btrfs  $FSTYPE "
        MISSING_SUBVOLUMES+=("$SUBVOLUME")
    fi
done
if [[ ! ${MISSING_SUBVOLUMES[@]} -gt 0 ]]; then
	exit 1
fi
echo "✅ Todos los subvolúmenes están correctamente montados en Btrfs.
# Se borran los volúmenes antiguos
for dir in "${SUBVOLUMES[@]}" ; do
    if [[ -d "/${dir}-old" ]] ; then
      rm -rvf "/${dir}-old"
    fi
done

##### FIN - Verificar si han sido creados los volumenes

