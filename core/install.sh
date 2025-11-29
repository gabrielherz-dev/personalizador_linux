# !/bin/bash
# Instalación de programas
#
readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RUTA_ACTUAL/App.class.sh"
source "$RUTA_ACTUAL/GnomeApp.class.sh"
source "$RUTA_ACTUAL/FlatApp.class.sh"
source "$RUTA_ACTUAL/LightdmApp.class.sh"
# Instalación base

#App.new BASE
#App.installApps BASE
#GnomeApp.new GNOME
#GnomeApp.installApps GNOME
#GnomeApp.installConfig GNOME
LightdmApp.new LIGHTDM
LightdmApp.installConfig LIGHTDM "DEBIAN"
#FlatApp.installApps FLATAPP
