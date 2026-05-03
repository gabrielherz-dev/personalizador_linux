#!/bin/bash
# Configuración de Snapper Automático para Flatpak

if [[ ! $EUID -eq 0 ]]; then
    echo "Se requieren permisos de root."
    exit 1
fi

# Definimos los subvolúmenes de Flatpak que creaste con el script anterior
# Formato: "NombreConfig:Ruta"
FLATPAK_PATHS=(
    "flatpak_user:/home/gherz/.local/share/flatpak"
    "flatpak_system:/var/lib/flatpak"
)

for item in "${FLATPAK_PATHS[@]}"; do
    CONFIG="${item%%:*}"
    VPATH="${item#*:}"

    echo "⚙️ Configurando Snapper para: $VPATH"

    # 1. Crear la configuración si no existe
    if ! snapper -c "$CONFIG" get-config &>/dev/null; then
        snapper -c "$CONFIG" create-config "$VPATH"
    fi

    # 2. Aplicar política de retención (10 capturas máximo, limpieza diaria)
    # NUMBER_LIMIT=10: Mantiene las últimas 10 capturas manuales/de instalación
    # TIMELINE_LIMIT_DAILY=10: Mantiene 10 capturas diarias (1 por día si el PC está encendido)
    # Los otros límites en 0 aseguran que no guarde copias por hora, mes o año.
    
    snapper -c "$CONFIG" set-config \
        "ALLOW_GROUPS=users" \
        "SYNC_ACL=yes" \
        "NUMBER_CLEANUP=yes" \
        "NUMBER_LIMIT=10" \
        "NUMBER_LIMIT_IMPORTANT=5" \
        "TIMELINE_CLEANUP=yes" \
        "TIMELINE_LIMIT_HOURLY=0" \
        "TIMELINE_LIMIT_DAILY=10" \
        "TIMELINE_LIMIT_WEEKLY=0" \
        "TIMELINE_LIMIT_MONTHLY=0" \
        "TIMELINE_LIMIT_YEARLY=0"

    # 3. Ajustar permisos para la carpeta de snapshots
    chown :users "$VPATH/.snapshots"
    chmod 750 "$VPATH/.snapshots"
    
    echo "✅ Configuración '$CONFIG' lista y automatizada."
done

# Asegurarse de que los servicios de Snapper estén activos en el sistema
systemctl enable --now snapper-timeline.timer snapper-cleanup.timer

echo "🚀 Snapper ahora gestionará Flatpak automáticamente cada día."
