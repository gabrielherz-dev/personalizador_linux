# !/bin/bash
# Clase para la instalación de aplicaciones del sistema
#
readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RUTA_ACTUAL/../config/constantes.sh"
source "$RUTA_ACTUAL/App.class.sh"

declare -A GnomeApp

GnomeApp.new() {
  local self=$1
  #Declaro mi propio this como un arreglo global de propiedades
  declare -gA $self
  #El equivalente a super() en otros lenguajes, heredo los atributos y métodos de mi clase padre
  App.new "$self"
  #Creo un puntero para tratar el atributo
  declare -n rself="$self"
  #Borro los atributos de mi clase padre, solo me interesan los de esta clase hija
  unset self
  rself["gnome-session"]="gnome-session"
  rself["gnome-settings-daemon"]="gsettings list-schemas"
  rself["gnome-control-center"]="gnome-control-center"
  rself["mutter"]="mutter"
  rself["gnome-shell"]="gnome-shell"
  rself["gnome-themes-extra"]="gnome-tweaks"
  rself["gnome-backgrounds"]="gnome-control-center"
  rself["adwaita-icon-theme"]="adwaita-icon-theme"
  rself["dconf-editor"]="dconf help"
  rself["gnome-shell-extensions"]="gnome-shell-extension-tool"
  rself["gnome-tweaks"]="gnome-tweaks"
  rself["xbindkeys"]="gsettings"
  rself["xdotool"]="xdotool"
  #rself["gnome-core"]="gnome-session"

}

# Métodos heredados
# INVOCACIÓN AL MÉTODO SUPER (PADRE)
GnomeApp.installApps() {
  App.installApps "$@"
  # Instala typescript para que puedan utilizarse los pluggins de GnomeShell
  #if [[ -n $(command -n "npm") ]]; then
  npm install -g typescript
  #fi
}

GnomeApp.installConfig() {
  #Para que arranque la sesión de gnome al iniciar sesión
  echo "exec gnome-session" >~/.xinitrc
  installDarkTheme
}

GnomeApp.install() {
  apt install --y $1 | tee -a $LOG_INSTALLATION
}

GnomeApp.checkInstall() {
  if [[ -n $(command -n "$1") ]]; then
    echo true
  fi
}
installDarkTheme() {
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
}
