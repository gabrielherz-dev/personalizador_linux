#!/bin/bash

# ==========================
# Personalizador de Debian
# ==========================
#

readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Importar clases y scripts  
source "$RUTA_ACTUAL/config/constantes.sh"
source "$RUTA_ACTUAL/core/App.class.sh"
source "$RUTA_ACTUAL/core/FlatApp.class.sh"

# Validar que dialog esté instalado
command -v dialog >/dev/null 2>&1 || {
  echo "Se requiere el paquete 'dialog'. Instálalo con: sudo apt install dialog"
  exit 1
}

# Copiar .dialogrc si existe
DIALOGRC_ORIG="$RUTA_ORIGEN/config/.dialogrc"
DIALOGRC_DEST="$HOME/.config/.dialogrc"
mkdir -p "$HOME/.config"

if [[ -f "$DIALOGRC_ORIG" ]]; then
  cp "$DIALOGRC_ORIG" "$DIALOGRC_DEST"
  export DIALOGRC="$DIALOGRC_DEST"
else
  echo "Advertencia: config/.dialogrc no encontrado, usando configuración por defecto."
fi

# Permitir que el usuario elija entre stable o testing
UBUNTU_BRANCH=$(dialog --clear \
  --backtitle "Selector de personalización de POP OS" \
  --title "¿Qué versión de personalización quieres usar?" \
  --menu "Selecciona tu versión para personalizar las opciones de instalación:" \
  15 50 2 \
  stable "COSMIC POP OS LTS 24.04" \
  3>&1 1>&2 2>&3)

# Cancelado o error
if [ $? -ne 0 ]; then
  clear
  echo "Operación cancelada."
  exit 1
fi

# Elegir Tema
THEME_SELECTED=$(dialog --clear \
  --backtitle "Selector de personalización de COSMIC-POPOS" \
  --title "¿Cuál tema deseas usar?" \
  --menu "Selecciona el tema :" \
  15 50 2 \
  THINKPAD "THINKPAD" \
  3>&1 1>&2 2>&3)

# Opciones según la versión seleccionada
#if [[ "$UBUNTU_BRANCH" == "stable" ]]; then

# Obtener el ID de usuario numérico
#USER_ID=$(id -u)
# Obtener el nombre de usuario actual
CURRENT_USER=$(whoami)
IS_ROOT="NO_ROOT"
OPTIONS=() 
# Las opciones varían según el tipo de usuario
if [[ $EUID -eq 0 ]]; then
  IS_ROOT="ROOT"
   apt update
  apt upgrade
#Antes de ejecutar las opciones de instalación, cambio los permisos a los ficheros ejecutables para el usuario actual
 chmod -R u+x  .
  OPTIONS=(

    1 "Instalar APP" on
    6 "Instalar FLATPAK" on
    7 "Crear Subvolumenes" off
    8 "Instalar perfiles AppArmour" off
  )
fi  
if [[ "$CURRENT_USER" == "gherz" ]]; then
  # Me hago dueño de todos los ficheros como usuario 
  sudo chown -R $USER:$USER .
#Antes de ejecutar las opciones de instalación, cambio los permisos a los ficheros ejecutables para el usuario actual
  sudo chmod -r u+x .
  OPTIONS=(
    4 "Instalar LazzyVim" on
    5 "Instalar tema RANGER" on
    7 "Instalar configuración de Cosmic" off
  )
fi


# Mostrar el checklist según la selección
CHOICES=$(dialog --clear \
  --backtitle "Personalizador de UBUNTU ($UBUNTU_BRANCH)" \
  --title "Opciones de instalación para $UBUNTU_BRANCH" \
  --checklist "Selecciona lo que deseas instalar:" \
  20 60 10 \
  "${OPTIONS[@]}" \
  3>&1 1>&2 2>&3)

clear

# Ejecutar acciones según las elecciones
for CHOICE in $(echo "$CHOICES" | sed 's/"//g'); do
  case "$IS_ROOT-$CHOICE" in
  "NO_ROOT-4")
    echo "Instalando Nvim/LazzyVim..."
    #core/install_nvim_src.sh
    core/install_lazzyvim.sh
    ;;
  "NO_ROOT-5")
    echo "Instalando tema RANGER..."
    cp -r "$RUTA_ORIGEN/config/ranger" "$HOME/.config"
    ;;
  "NO_ROOT-7")
    echo "Instalando configuración de Cosmic.."
    #No instalo el configurador de cosmic porque la api consmic-settings-control no está disponible en el binario actual
#    core/COSMIC/config_cosmic.sh
    core/COSMIC/config_gtk_qt.sh
    ;;

  "ROOT-1")
    echo "Instalando Comandos Base..."
    App.new BASE
    App.installApps BASE
    ;;
  "ROOT-6")
    echo "Instalando FLAT APPS..."
    FlatApp.new FL
    FlatApp.installApps FL
    ;;
  "ROOT-7")
    echo "Creando Subvolúmenes..."
    core/install_subvolumenes.sh
    # core/crear_subvols.sh
    ;;
  "ROOT-8")
    echo "Instalando perfiles AppArmor..."
    core/seguridad/crear_perfiles_apparmor.sh
    # sudo apt install apparmor-profiles apparmor-utils
    ;;
  *)
    echo "Opción no reconocida: $CHOICE"
    ;;
  esac
done

# Cambiando los permisos en el directorio del usuario
chown -R gherz:gherz /home/gherz
find /home/gherz -type d -exec chmod 755 {} +
find /home/gherz -type f -exec chmod 644 {} +

echo "Personalización completada para Debian $UBUNTU_BRANCH"
