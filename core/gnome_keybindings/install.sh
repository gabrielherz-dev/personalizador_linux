# !/bin/bash
# Instalación de POP-shell y keybindings
readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RUTA_ACTUAL/../../config/constantes.sh"

#Ya no hace falta instalar pop shell
#$RUTA_ACTUAL/install_popshell_plugin.sh -y

#Instalación del plugin tilling assistant para GNOME
$RUTA_ACTUAL/install_tilling_assistant_plugin.sh -y
# Instalación de los scripts en bash para los keybindings
$RUTA_ACTUAL/core/reboot_keybinding.sh
$RUTA_ACTUAL/core/screenshots_keybinding.sh
#Ya no hace falta instalar el zoom
#$RUTA_ACTUAL/core/zoom_keybinding.sh
# Instalación del resto de keybindings que no requieren scripts bash
$RUTA_ACTUAL/install_keybindings.sh
