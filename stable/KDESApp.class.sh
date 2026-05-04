 # !/bin/bash
 # Clase para la instalación del gestor de ventanas KDE
 #
readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RUTA_ACTUAL/../config/constantes.sh"
source "$RUTA_ACTUAL/App.class.sh"

 declare -A KDESApp

 KDESApp.new(){
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

 	#rself["kde-plasma-desktop"]="plasma-open-settings --version"
  rself["plasma-workspace-wayland"]="plasma-emojier"
  rself["sddm"]="sddm --test-mode"
  rself["sddm-theme-breeze"]="sddm --test-mode"
  rself["systemsettings"]="systemsettings --version"
  ref["kate"]="kate --version"
  ref["ark"]="ark --version"
  ref["kcalc"]="kcalc --version"
  ref["gwenview"]="gwenview --version"
  ref["okular"]="okular --version"
  ref["spectacle"]="spectacle --version"
  ref["kdeconnect-kde"]="kdeconnect-cli --version"
  ref["kmail"]="kmail --version"
  ref["marknotes"]="marknotes --version"
  ref["akregator"]="akregator --version"
}

# Métodos heredados
KDESApp.installApps(){
  #Instala KDE sin las aplicaciones secundarias, es necesario el flag
  apt install --no-install-recommends kde-plasma-desktop
  # INVOCACIÓN AL MÉTODO SUPER (PADRE)
  App.installApps "$@" 

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

# Copiar los wallpapers
  cp -rf "$RUTA_ORIGEN/config/wallpapers" /usr/share/

# habillita el inicio de sesión 
  systemctl enable sddm
  systemctl set-default graphical.target
}


KDESApp.install(){
	apt install --y $1 | tee -a $LOG_INSTALLATION
}

KDESApp.checkInstall(){
	if[[ -n $( command -n "$1" ) ]]; then
                echo true
        fi
}

