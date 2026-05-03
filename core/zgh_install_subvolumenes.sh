#!/bin/bash
# Creación de subvolúmenes Btrfs en openSUSE (Versión Corregida)

if [[ ! $EUID -eq 0 ]]; then
    echo "Se requieren permisos de root."
    exit 1
fi

MAIN_USER="gherz"
USER_HOME="/home/$MAIN_USER"
ROOT_UUID=$(findmnt -no UUID /)
# openSUSE usa el prefijo @ para los subvolúmenes
PREFIX="@"
OPTIONS="defaults"

# Lista de subvolúmenes (limpiamos posibles espacios o caracteres ocultos)
SUBVOLUMES=(
    "home/$MAIN_USER/.local/share/flatpak"
    "/var/lib/flatpak"
)

echo "🛠️ Limpiando entradas previas fallidas en /etc/fstab..."
# Esto elimina las líneas mal formadas del intento anterior para evitar duplicados
for dir in "${SUBVOLUMES[@]}"; do
    dir_clean=$(echo "$dir" | tr -d '\r')
    sed -i "\| /$dir_clean |d" /etc/fstab
done

echo "🛠️ Generando subvolúmenes Btrfs..."

for dir in "${SUBVOLUMES[@]}" ; do
    # Limpieza crucial de caracteres invisibles
    dir=$(echo "$dir" | tr -d '\r' | xargs)
    TARGET="/$dir"
    SUBVOL_PATH="${PREFIX}/${dir}"
    
    mkdir -p "$(dirname "$TARGET")"

    if btrfs subvolume show "$TARGET" &>/dev/null; then
        echo "✅ $TARGET ya es un subvolumen."
    else
        if [[ -d "$TARGET" ]]; then
            # Caso especial para /tmp (no migrar contenido si da error)
            if [[ "$dir" == "tmp" ]] || [[ -z "$(ls -A "$TARGET" 2>/dev/null)" ]]; then
                echo "📦 Creando subvolumen limpio en $TARGET..."
                rm -rf "$TARGET"
                btrfs subvolume create "$TARGET"
            else
                echo "📦 Migrando directorio existente $TARGET..."
                mv "$TARGET" "${TARGET}_old"
                btrfs subvolume create "$TARGET"
                cp -ax "${TARGET}_old/." "$TARGET/"
                rm -rf "${TARGET}_old"
            fi
        else
            btrfs subvolume create "$TARGET"
        fi
    fi

    # Agregar a /etc/fstab con formato limpio
    echo "Adding $dir to fstab..."
    # Usamos un formato simple separado por espacios/tabuladores para evitar errores de análisis
    echo "UUID=$ROOT_UUID  /$dir  btrfs  ${OPTIONS},subvol=${SUBVOL_PATH}  0  0" >> /etc/fstab
done

# Ajuste de permisos
chown -R "$MAIN_USER:$MAIN_USER" "$USER_HOME"
chmod 0700 "$USER_HOME/.ssh" "$USER_HOME/.gnupg" 2>/dev/null

echo "🔄 Recargando montajes..."
systemctl daemon-reload
mount -a

echo "🚀 Proceso completado. Los subvolúmenes están configurados correctamente."
