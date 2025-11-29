 # !/bin/bash
 # Clase para la instalación de aplicaciones relacionadas con el gestor i3wm

readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RUTA_ACTUAL/../config/constantes.sh"
source "$RUTA_ACTUAL/App.class.sh"

 declare -A I3wmApp

 I3wmApp.new(){
	local self=$1
  #Tema a usar para personalizar la apariencia
  local tema=$2
	#Declaro mi propio this como un arreglo global de propiedades
	declare -gA $self
	#El equivalente a super() en otros lenguajes, heredo los atributos y métodos de mi clase padre
	App.new "$self"
	#Creo un puntero para tratar el atributo
	declare -n rself="$self"
	#Borro los atributos de mi clase padre, solo me interesan los de esta clase hija
	unset self
	rself["i3"]="i3-msg"
	rself["rofi"]="rofi"
  rself["gnome-control-center"]="gnome-control-center"
	rself["gnome-settings-daemon"]="gnome-settings-daemon"
  rself["gnome-bluetooth"]="gnome-bluetooth"
  rself["gnome-online-accounts"]="gnome-online-accounts"
  rself["gnome-shell-common"]="gnome-shell-common"
  rself["xzoom"]="xzoom"
  rself["feh"]="feh"
  rself["dunst"]="dunstify"
}
# Métodos heredados
I3wmApp.installApps(){
  # INVOCACIÓN AL MÉTODO SUPER (PADRE)
  App.installApps "$@" 
  #Instalar tema de i3wm
  # Ruta donde tienes el tema actualmente
  RUTA_ORIGEN_I3="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ##directorio donde se guardará la configuración del entorno de escritorio
  #TARGET_USER="$(logname)"
  #TARGET_HOME="/home/$TARGET_USER"
	if [[ ! -d "$TARGET_HOME/.config/i3" ]]; then
		mkdir -p "$TARGET_HOME/.config/i3"
	fi	
  if [[ "$tema" == "$THINKPAD_THEME" ]]; then 
    cp "$RUTA_ORIGEN_I3/config/THINKPAD/i3/config" "$TARGET_HOME/.config/i3/config"
    cp -rf "$RUTA_ORIGEN_I3/config/i3/i3status.conf" /etc/i3
  fi
  if [[ "$tema" == "$DEBIAN_THEME" ]]; then 
    cp "$RUTA_ORIGEN_I3/config/DEBIAN/i3/config" "$TARGET_HOME/.config/i3/config"
    cp -rf "$RUTA_ORIGEN_I3/config/i3/i3status.conf" /etc/i3
  fi
  cp -r "$RUTA_ORIGEN_I3/config/wallpapers" /usr/share/

  #Instalar rofi 
  #director>io donde se guardará la configuración del entorno de escritorio
  #if [[ ! -d "$TARGET_HOME/.config/rofỉ" ]]; then
  #          mkdir -p "$TARGET_HOME/.config/rofi"
  #fi
	cp -r "$RUTA_ORIGEN_I3/config/i3/rofi" "$TARGET_HOME/.config" 
  #
  # Tema oscuro para los programas de configuración de gnome como el de conexiones de red, sonido, etc
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
}


I3wmApp.install(){
	apt install --y $1 | tee -a $LOG_INSTALLATION
}

I3wmApp.checkInstall(){
	if[[ -n $( command -n "$1" ) ]]; then
                echo true
        fi
}

