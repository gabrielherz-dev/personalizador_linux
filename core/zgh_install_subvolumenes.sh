#!/bin/bash
# Creación de subvolúmenes Btrfs en openSUSE

if [[ ! $EUID -eq 0 ]]; then
    echo "Se requieren permisos de root."
    exit 1
fi

MAIN_USER="gherz"
USER_HOME="/home/$MAIN_USER"
ROOT_UUID=$(findmnt -no UUID /)
# Opciones estándar de openSUSE (ajusta si prefieres compresión zstd)
OPTIONS="defaults"

# Lista de subvolúmenes deseados
SUBVOLUMES=(
    "opt"
    "tmp"
    "home/$MAIN_USER"
    "home/$MAIN_USER/.ssh"
    "home/$MAIN_USER/.gnupg"
    "home/$MAIN_USER/.local/share/flatpak"
    "home/$MAIN_USER/var/lib/flatpak"
)

echo "🛠️ Generando subvolúmenes Btrfs..."

for dir in "${SUBVOLUMES[@]}" ; do
    TARGET="/$dir"
    
    # Crear ruta de directorios padres si no existen
    mkdir -p "$(dirname "$TARGET")"

    # Verificar si ya es un subvolumen
    if btrfs subvolume show "$TARGET" &>/dev/null; then
        echo "✅ $TARGET ya es un subvolumen."
    else
        if [[ -d "$TARGET" ]]; then
            echo "📦 Migrando directorio existente $TARGET..."
            mv "$TARGET" "${TARGET}_old"
            btrfs subvolume create "$TARGET"
            cp -ax "${TARGET}_old/." "$TARGET/"
            rm -rf "${TARGET}_old"
        else
            btrfs subvolume create "$TARGET"
        fi
    fi

    # Agregar a /etc/fstab si no existe
    if ! grep -q "subvol=$dir " /etc/fstab; then
        echo "Adding $dir to fstab..."
        printf "UUID=%-36s /%-25s btrfs   subvol=%-30s %-s 0 0\n" \
            "$ROOT_UUID" "$dir" "$dir" "$OPTIONS" >> /etc/fstab
    fi
done

# Ajuste de permisos específicos
chown -R "$MAIN_USER:$MAIN_USER" "$USER_HOME"
chmod 0700 "$USER_HOME/.ssh" "$USER_HOME/.gnupg"

systemctl daemon-reload
mount -a
echo "🚀 Subvolúmenes listos."
