#!/bin/bash
# Configuración de Snapper en openSUSE

if [[ ! $EUID -eq 0 ]]; then
    echo "Se requieren permisos de root."
    exit 1
fi

# El instalador de openSUSE ya suele tener una config para '/' llamada 'root'
# Aquí crearemos una configuración específica para /home/$MAIN_USER si no existe

CONFIG_NAME="home_user"
USER_PATH="/home/gherz"

echo "📸 Configurando Snapper para $USER_PATH..."

if snapper -c "$CONFIG_NAME" get-config &>/dev/null; then
    echo "La configuración '$CONFIG_NAME' ya existe."
else
    # 1. Crear la configuración inicial
    snapper -c "$CONFIG_NAME" create-config "$USER_PATH"
    
    # 2. Establecer límites de retención (Estándar de openSUSE)
    snapper -c "$CONFIG_NAME" set-config \
        "NUMBER_CLEANUP=yes" \
        "NUMBER_LIMIT=10" \
        "NUMBER_LIMIT_IMPORTANT=10" \
        "TIMELINE_CLEANUP=yes" \
        "TIMELINE_LIMIT_HOURLY=10" \
        "TIMELINE_LIMIT_DAILY=10" \
        "TIMELINE_LIMIT_MONTHLY=1" \
        "TIMELINE_LIMIT_YEARLY=0"
fi

# Asegurar que el usuario pueda ver sus propios snapshots sin sudo (opcional)
chown :users "$USER_PATH/.snapshots"

echo "✅ Snapper configurado. Puedes listar snapshots con: snapper -c $CONFIG_NAME list"
