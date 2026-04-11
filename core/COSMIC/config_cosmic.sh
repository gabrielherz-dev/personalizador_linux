#!/bin/bash

echo "=== Iniciando configuración de COSMIC Desktop vía API ==="

# 1. Habilitar el Modo Oscuro (Global)
cosmic-settings-control set org.freedesktop.appearance color-scheme 'prefer-dark'

# 2. Configurar el Panel (Dock) para que se oculte automáticamente
cosmic-settings-control set com.system76.CosmicPanel.Panel:bottom autohide 'Always'

# 3. Barra de Status Superior Dinámica (Opacidad/Comportamiento)
cosmic-settings-control set com.system76.CosmicPanel.Panel:top opacity 0.5

# 4. Establecer Wallpaper por defecto
WALLPAPER_PATH="/usr/share/wallpapers/wallpaper_thinkpad.jpg"
if [ -f "$WALLPAPER_PATH" ]; then
    cosmic-settings-control set com.system76.CosmicBackground wallpaper "$WALLPAPER_PATH"
else
    echo "Wallpaper no encontrado en $WALLPAPER_PATH, omitiendo..."
fi

# 5. Activar el Zoom de Accesibilidad (Lupa de pantalla)
cosmic-settings-control set com.system76.CosmicAccessibility screen-magnifier-enabled true
cosmic-settings-control set com.system76.CosmicAccessibility screen-magnifier-scale 2.0

# 6. Gestión del Applet de Numeración (Applet Workspaces/Desktop Numbers)
sudo apt update && sudo apt install -y cosmic-applet-workspaces

# Para añadirlo a la barra superior dinámicamente:
cosmic-settings-control set com.system76.CosmicPanel.Panel:top applet-fill-list "['com.system76.CosmicAppletWorkspaces']"

echo "=== Configuración aplicada con éxito ==="
