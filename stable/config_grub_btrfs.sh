#!/bin/bash

# Verificar si es superusuario
if [[ ! $EUID -eq 0 ]]; then
    echo "Ejecutar con sudo/su"
    exit 1
fi

# 1. Instalar grub-btrfs y inotify-tools (necesario para el demonio automático)
echo "Instalando grub-btrfs..."
apt-get update
apt-get install -y grub-btrfs inotify-tools

# 2. Configurar grub-btrfs para mostrar un máximo de 10 snapshots
CONFIG_FILE="/etc/default/grub-btrfs/config"

if [ -f "$CONFIG_FILE" ]; then
    # Hacer respaldo por si acaso
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
    
    # Descomentar y cambiar el límite o agregarlo si no existe
    if grep -q "GRUB_BTRFS_LIMIT=" "$CONFIG_FILE"; then
        sed -i 's/.*GRUB_BTRFS_LIMIT=.*/GRUB_BTRFS_LIMIT="10"/' "$CONFIG_FILE"
    else
        echo 'GRUB_BTRFS_LIMIT="10"' >> "$CONFIG_FILE"
    fi
else
    # Si no existe en Debian, probar en la configuración general de grub
    echo "No se encontró $CONFIG_FILE. Añadiendo a /etc/default/grub..."
    if ! grep -q "GRUB_BTRFS_LIMIT=" /etc/default/grub; then
        echo 'GRUB_BTRFS_LIMIT="10"' >> /etc/default/grub
    else
        sed -i 's/.*GRUB_BTRFS_LIMIT=.*/GRUB_BTRFS_LIMIT="10"/' /etc/default/grub
    fi
fi

# 3. Actualizar el GRUB para que tome los cambios
echo "Actualizando GRUB..."
update-grub

# 4. Habilitar el demonio para que actualice GRUB automáticamente al crear/borrar un snapshot
echo "Habilitando el demonio grub-btrfsd..."
systemctl enable --now grub-btrfsd

echo "✅ Configuración de GRUB-BTRFS finalizada. Ahora verás los últimos 10 snapshots de la raíz al arrancar el equipo."
