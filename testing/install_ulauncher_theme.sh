#!/bin/bash
set -euo pipefail
# NOTA: SE DEBE DE ASIGNAR EL TEMA EN LAS PREFERENCIAS DE ULAUNCHER

THEME_DIR="$HOME/.config/ulauncher/user-themes"
THEME_NAME="dracula"

echo "📦 Instalando tema Dracula para Ulauncher..."

# Crear carpeta si no existe
mkdir -p "$THEME_DIR"

# Si ya existe el tema, actualizarlo
if [ -d "$THEME_DIR/$THEME_NAME" ]; then
    echo "🔄 Tema Dracula ya existe, actualizando..."
    git -C "$THEME_DIR/$THEME_NAME" pull
else
    echo "⬇️  Descargando tema Dracula..."
    git clone https://github.com/dracula/ulauncher.git "$THEME_DIR/$THEME_NAME"
fi

# Activar tema en la configuración de Ulauncher
CONFIG_FILE="$HOME/.config/ulauncher/settings.json"
if [ -f "$CONFIG_FILE" ]; then
    echo "🖌  Activando tema Dracula en configuración..."
    jq '.+={"theme": "dracula"}' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
else
    echo "⚠️ No existe settings.json, se creará con el tema Dracula."
    mkdir -p "$(dirname "$CONFIG_FILE")"
    echo '{"theme": "dracula"}' > "$CONFIG_FILE"
fi

echo "✅ Tema Dracula instalado y activado. Reinicia Ulauncher para aplicar los cambios."

