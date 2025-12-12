#!/bin/bash

# ==========================
# Personalizador de Debian
# ==========================
#

readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Importar clases y scripts  
source "$RUTA_ACTUAL/config/constantes.sh"
source "$RUTA_ACTUAL/core/GnomeApp.class.sh"
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
  --backtitle "Selector de personalización de UBUNTU" \
  --title "¿Qué versión de personalización quieres usar?" \
  --menu "Selecciona tu versión para personalizar las opciones de instalación:" \
  15 50 2 \
  stable "UBUNTU LTS Server" \
  3>&1 1>&2 2>&3)

# Cancelado o error
if [ $? -ne 0 ]; then
  clear
  echo "Operación cancelada."
  exit 1
fi

# Elegir Tema
THEME_SELECTED=$(dialog --clear \
  --backtitle "Selector de personalización de UBUNTU" \
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
  OPTIONS=(

    1 "Instalar APP" on
    3 "Instalar GRUB" on
    4 "Instalar Ahorro de batería" off
    6 "Instalar FLATPAK" on
    7 "Crear Subvolumenes" off
    8 "Instalar perfiles AppArmour" off
    9 "Instalar GNOME" off
    13 "Instalar tema ULAUNCHER" off
  )
fi  
if [[ "$CURRENT_USER" == "gherz" ]]; then
  OPTIONS=(
    4 "Instalar LazzyVim" on
    5 "Instalar tema RANGER" on
    6 "Instalar tema Wezterm" on
  )
fi
#El tilling window assistant para GNOME se instala desde una sesión GNOME iniciada
if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"*
      && "$CURRENT_USER" == "gherz" ]]; then
  OPTIONS=(
    1 "Instalar Tilling-assistant para GNOME" on
  )
fi

#Antes de ejecutar las opciones de instalación, cambio los permisos a los ficheros ejecutables para el usuario actual
find . -type f -exec grep -Il '^#!' {} \; -exec chmod u+x {} \;


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
  "NO_ROOT-1")
    echo "Instalando POP-SHELL para GNOME con Keybindings..."
    # sudo apt install -y gnome-core gdm3
    core/gnome_keybindings/install.sh
    ;;
  "NO_ROOT-4")
    echo "Instalando Nvim/LazzyVim..."
    #core/install_nvim_src.sh
    core/install_lazzyvim.sh
    ;;
  "NO_ROOT-5")
    echo "Instalando tema RANGER..."
    cp -r "$RUTA_ORIGEN/config/ranger" "$HOME/.config"
    ;;
  "NO_ROOT-6")
    echo "Instalando Wezterm..."
    core/install_wezterm.sh
    mkdir -p "$HOME/.config/wezterm"
    cp -r "$RUTA_ORIGEN/config/wezterm" "$HOME/.config"
    ;;


  "ROOT-1")
    echo "Instalando Comandos Base..."
    App.new BASE
    App.installApps BASE
    ;;
  "ROOT-3")
    echo "Instalando Tema de GRUB..."
    core/install_grub_theme.sh "$THEME_SELECTED"
    core/install_fuente_grub_tty.sh
    core/install_fuentes_initramfs_tty.sh
    ;;
  "ROOT-4")
    echo "Instalando Ahorro de Batería..."
    core/install_battery_save.sh
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
  "ROOT-9")
    echo "Instalando GNOME..."
    GnomeApp.new GN
    GnomeApp.installApps GN
    GnomeApp.installConfig GN
    ;;
  "ROOT-13")
    echo "Instalando tema de ulauncher..."
    core/install_ulauncher_theme.sh
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
