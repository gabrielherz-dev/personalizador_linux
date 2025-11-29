# !/bin/bash
# Instalación de POP-shell y keybindings
readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RUTA_ACTUAL/../../config/constantes.sh"
#source ../../config/constantes.sh
#  # Ruta donde tienes el tema actualmente
#RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Instalación del plugin pop-shell para simulación de un tilling window
# La opción -y es porque pregunta a la hora de compilar con make local-install
$RUTA_ACTUAL/install_popshell_plugin.sh -y
# Instalación de los scripts en bash para los keybindings
$RUTA_ACTUAL/core/reboot_keybinding.sh
$RUTA_ACTUAL/core/screenshots_keybinding.sh
$RUTA_ACTUAL/core/zoom_keybinding.sh
# Instalación del resto de keybindings que no requieren scripts bash
$RUTA_ACTUAL/install_keybindings.sh
