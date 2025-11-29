#!/usr/bin/env bash

readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RUTA_ACTUAL/../config/constantes.sh"

###### INSTALACIÓN DE LA CONFIGURACIÓN DE OTRO SISTEMA KDE ######
# Ruta donde tienes el tema actualmente
RUTA_ORIGEN_KDE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
##directorio donde se guardará la configuración del entorno de escritorio, shortcuts, etc
if [[ ! -d "$TARGET_HOME/.config" ]]; then
  mkdir -p "$TARGET_HOME/.config"
fi
##directorio donde se guardará la configuración del entorno de plasma
if [[ ! -d "$TARGET_HOME/.local/share/plasma" ]]; then
  mkdir -p "$TARGET_HOME/.local/share/plasma"
fi
# Instalación del tema, los shortcutsy configuración del panel
if [[ "$tema" == "$THINKPAD_THEME" ]]; then
  cp -rf "$RUTA_ORIGEN_KDE/config/THINKPAD/kde/share" "$TARGET_HOME/.local/share"
  cp -rf "$RUTA_ORIGEN_KDE/config/THINKPAD/kde/config" "$TARGET_HOME/.config"
fi
if [[ "$tema" == "$DEBIAN_THEME" ]]; then
  cp -rf "$RUTA_ORIGEN_KDE/config/DEBIAN/kde/share" "$TARGET_HOME/.local/share"
  cp -rf "$RUTA_ORIGEN_KDE/config/DEBIAN/kde/config" "$TARGET_HOME/.config"
fi
# Copiar los wallpapers
cp -rf "$RUTA_ORIGEN/config/wallpapers" /usr/share/

# habillita el inicio de sesión
systemctl enable sddm
systemctl set-default graphical.target
