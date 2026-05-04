#!/bin/bash

# Verificar si es superusuario
if [[ ! $EUID -eq 0 ]]; then
    echo "Ejecutar con sudo/su"
    exit 1
fi

MAIN_USER="gherz"

# 1. Instalar Snapper
echo "Instalando snapper..."
apt-get update
apt-get install -y snapper

# 2. Configurar el Root (/) que es el más importante para restaurar el sistema
echo "Creando configuración de snapper para la raíz (/)..."
if [ ! -f /etc/snapper/configs/root ]; then
    snapper -c root create-config /
else
    echo "La configuración 'root' ya existe."
fi

# Listado de subvolúmenes a configurar (opcional: Snapper generalmente solo se usa para / y /home,
# pero como solicitaste para estos subvolúmenes, aquí los iteramos).
SUBVOLUMES=(
    "opt"
    "var/cache"
    "var/lib/sddm"
    "var/log"
    "var/spool"
    "home/$MAIN_USER"
    "home/$MAIN_USER/.local/share/flatpak"
    "home/$MAIN_USER/var/lib/flatpak"
    "home/$MAIN_USER/.local/share/distrobox"
)

# Crear configs para los demás subvolúmenes
for dir in "${SUBVOLUMES[@]}"; do
    # Crear un nombre de config seguro (reemplazando / y . por guiones)
    CONF_NAME=$(echo "$dir" | sed -e 's/\//_/g' -e 's/\./_/g')
    if [ ! -f "/etc/snapper/configs/$CONF_NAME" ]; then
        echo "Creando configuración de snapper para /$dir (nombre: $CONF_NAME)..."
        snapper -c "$CONF_NAME" create-config "/$dir"
    fi
done

# 3. Modificar las reglas de retención a MÁXIMO 10 para TODAS las configuraciones
echo "Ajustando límites a 10 snapshots máximos..."
for config_file in /etc/snapper/configs/*; do
    sed -i 's/^NUMBER_LIMIT=.*/NUMBER_LIMIT="10"/' "$config_file"
    sed -i 's/^NUMBER_LIMIT_IMPORTANT=.*/NUMBER_LIMIT_IMPORTANT="0"/' "$config_file"
    sed -i 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="0"/' "$config_file"
    sed -i 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="10"/' "$config_file"
    sed -i 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="0"/' "$config_file"
    sed -i 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="0"/' "$config_file"
    sed -i 's/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' "$config_file"
done

# 4. Configurar systemd para que los snapshots automáticos se ejecuten CADA 3 DÍAS
echo "Sobrescribiendo el temporizador de snapper para ejecutarse cada 3 días..."
mkdir -p /etc/systemd/system/snapper-timeline.timer.d
cat <<EOF > /etc/systemd/system/snapper-timeline.timer.d/override.conf
[Timer]
# Limpiar el OnCalendar por defecto
OnCalendar=
# Ejecutar cada 3 días, empezando desde el día 1 del mes a media noche
OnCalendar=*-*-1/3 00:00:00
EOF

# Recargar systemd y habilitar los servicios de limpieza y timeline de Snapper
systemctl daemon-reload
systemctl enable --now snapper-timeline.timer
systemctl enable --now snapper-cleanup.timer

echo "✅ Snapper instalado y configurado para crear snapshots cada 3 días con un máximo de 10 retenciones."
