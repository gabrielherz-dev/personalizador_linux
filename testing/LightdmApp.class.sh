 # !/bin/bash
 # Clase para la instalación de aplicaciones relacionadas con el gestor de arranque LightDM 
 #
readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RUTA_ACTUAL/App.class.sh"
source "$RUTA_ACTUAL/../config/constantes.sh"

 declare -A lightdmApp

 LightdmApp.new(){
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

	rself["lightdm"]="lightdm"]
	rself["lightdm-gtk-greeter"]="lightdm-gtk-greeter"]
	rself["lightdm-gtk-greeter-settings"]="lightdm-gtk-greeter-settings"
	rself["adwaita-icon-theme"]="[ -d /usr/share/themes/Adwaita-dark ] && echo OK" 
	rself["papirus-icon-theme"]="[ -d /usr/share/icons/Papirus-Dark ] && echo OK" 
	rself["gnome-themes-extra"]="[ -d /usr/share/themes/Adwaita-dark ] && [ -d /usr/share/icons/Papirus-Dark ] && echo OK" 
}

# Métodos heredados 
LightdmApp.installConfig(){
  # INVOCACIÓN AL MÉTODO SUPER (PADRE)
  App.installApps "$@" 

  # Ruta del wallpaper 
  FONDO_ORIGEN="$RUTA_ORIGEN/config/wallpapers/wallpaper_debian_principal.jpg"
  FONDO_DESTINO="/usr/share/wallpapers/wallpaper_debian_principal.jpg"

  if [[ "$tema" == "$THINKPAD_THEME" ]]; then    
    # Ruta del wallpaper 
    FONDO_ORIGEN="$RUTA_ORIGEN/config/wallpapers/wallpaper_thinkpad.jpg"
    FONDO_DESTINO="/usr/share/wallpapers/wallpaper_thinkpad.jpg"
  fi
  if [[ "$tema" == "$DEBIAN_THEME" ]]; then 
    # Ruta del wallpaper 
    FONDO_ORIGEN="$RUTA_ORIGEN/config/wallpapers/wallpaper_debian_principal.jpg"
    FONDO_DESTINO="/usr/share/wallpapers/wallpaper_debian_principal.jpg"
  fi
    
   
  #Fichero de configuración de lightdm
  CONFIG_FILE="/etc/lightdm/lightdm-gtk-greeter.conf"
  LIGHTDM_CONF_DIR="/etc/lightdm/lightdm.conf.d"
  GTK_GREETER_CONF="$LIGHTDM_CONF_DIR/99-gtk-greeter.conf"


  # Crear el archivo 99-gtk-greeter.conf si no existe
  mkdir -p "$LIGHTDM_CONF_DIR"
  echo "[Seat:*]
  greeter-session=lightdm-gtk-greeter" > "$GTK_GREETER_CONF"

  # Copiar fondo personalizado
  echo "Copiando fondo personalizado a $FONDO_DESTINO..."
  cp "$FONDO_ORIGEN" "$FONDO_DESTINO"
  chmod 644 "$FONDO_DESTINO"

  # Crear/modificar configuración del greeter
  echo "Actualizando $CONFIG_FILE..."
  cat > "$CONFIG_FILE" <<EOF
  [greeter]
  theme-name=Adwaita-dark
  icon-theme-name=Papirus-Dark
  background=$FONDO_DESTINO
EOF

  # Reiniciar LightDM
  echo "Reiniciando LightDM para aplicar cambios..."
  systemctl restart lightdm
}

LightdmApp.pinstall(){
	apt install --y $1 | tee -a $LOG_INSTALLATION
}

LightdmApp.checkInstall(){
	if [[ -n $( command -n "$1" ) ]]; then
                echo true
        fi
}

