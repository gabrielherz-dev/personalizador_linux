# !/bin/bash
# Asignar teclas (atajos) a aplicaciones de GNOME
readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RUTA_ACTUAL/../../config/constantes.sh"
#source ../../config/constantes.sh
#  # Ruta donde tienes el tema actualmente
#RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

$RUTA_ACTUAL/core/asignar_tecla.sh 'Print' "set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/" "binding"
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super>Delete' "org.gnome.settings-daemon.plugins.media-keys" "screensaver"
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super>d' "org.gnome.shell.keybindings" "toggle-application-view"
# Ampliación:
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super>a' "org.gnome.settings-daemon.plugins.media-keys" "magnifier"
#  mostrar todas las ventanas del tilling abierta:
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super>s' "org.gnome.shell.keybindings" "toggle-overview"
# mover entre escritorios
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super>1' "org.gnome.desktop.wm.keybindings" "switch-to-workspace-1"
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super>2' "org.gnome.desktop.wm.keybindings" "switch-to-workspace-2"
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super>3' "org.gnome.desktop.wm.keybindings" "switch-to-workspace-3"
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super>4' "org.gnome.desktop.wm.keybindings" "switch-to-workspace-4"
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super>5' "org.gnome.desktop.wm.keybindings" "switch-to-workspace-5"
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super>6' "org.gnome.desktop.wm.keybindings" "switch-to-workspace-6"
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super>7' "org.gnome.desktop.wm.keybindings" "switch-to-workspace-7"
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super>8' "org.gnome.desktop.wm.keybindings" "switch-to-workspace-8"
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super>9' "org.gnome.desktop.wm.keybindings" "switch-to-workspace-9"
# mover ventana al escritorio
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super><Shift>1' "org.gnome.desktop.wm.keybindings" "move-to-workspace-1"
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super><Shift>2' "org.gnome.desktop.wm.keybindings" "move-to-workspace-2"
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super><Shift>3' "org.gnome.desktop.wm.keybindings" "move-to-workspace-3"
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super><Shift>4' "org.gnome.desktop.wm.keybindings" "move-to-workspace-4"
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super><Shift>5' "org.gnome.desktop.wm.keybindings" "move-to-workspace-5"
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super><Shift>6' "org.gnome.desktop.wm.keybindings" "move-to-workspace-6"
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super><Shift>7' "org.gnome.desktop.wm.keybindings" "move-to-workspace-7"
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super><Shift>8' "org.gnome.desktop.wm.keybindings" "move-to-workspace-8"
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super><Shift>9' "org.gnome.desktop.wm.keybindings" "move-to-workspace-9"
# Redimensionar
$RUTA_ACTUAL/core/asignar_tecla.sh '<Super>r' "org.gnome.desktop.wm.keybindings" "begin-resize"
