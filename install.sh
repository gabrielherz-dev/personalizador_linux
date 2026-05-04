#!/bin/bash

# ==========================
# Personalizador de Debian 13
# ==========================
#

readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Importar clases y scripts  debian stable
source "$RUTA_ACTUAL/config/constantes.sh"
# Importar clases y scripts  debian stable
source "$RUTA_ACTUAL/stable/App.class.sh"
source "$RUTA_ACTUAL/stable/FlatApp.class.sh"
source "$RUTA_ACTUAL/stable/KDESApp.class.sh"

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
DEBIAN_BRANCH=$(dialog --clear \
  --backtitle "Selector de personalización de Debian 13" \
  --title "¿Qué versión de personalización quieres usar?" \
  --menu "Selecciona tu versión para personalizar las opciones de instalación:" \
  15 50 2 \
  stable "Versión STABLE" \
  testing "Versión testing y STABLE" \
  3>&1 1>&2 2>&3)

# Cancelado o error
if [ $? -ne 0 ]; then
  clear
  echo "Operación cancelada."
  exit 1
fi

# Elegir Tema
THEME_SELECTED=$(dialog --clear \
  --backtitle "Selector de personalización de Debian" \
  --title "¿Cuál tema deseas usar?" \
  --menu "Selecciona el tema :" \
  15 50 2 \
  DEBIAN "DEBIAN" \
  THINKPAD "THINKPAD" \
  3>&1 1>&2 2>&3)

# Opciones según la versión seleccionada
if [[ "$DEBIAN_BRANCH" == "stable" ]]; then
  OPTIONS=(
    1 "Instalar APP" on
    2 "Instalar GRUB" on 
    3 "Instalar KDE" off
    4 "Instalar LazzyVim" off
    5 "Instalar RANGER" off
    6 "Instalar Wezterm" off
    7 "Instalar FLATPAK" on
    8 "Crear Subvolumenes" off
    9 "Instalar perfiles AppArmour" off
  )
else
  # Se verifica que se tengan los pivilegios de root
  if [[ $EUID -ne 0 ]]; then
    echo "Este script necesita privilegios de superusuario."
    exit 1
  fi
  # Actualizar antes de proceder a instalar aplicaciones
  apt update
  apt upgrade
  #OPTIONS=(
  #)
fi

# Mostrar el checklist según la selección
CHOICES=$(dialog --clear \
  --backtitle "Personalizador de Debian ($DEBIAN_BRANCH)" \
  --title "Opciones de instalación para $DEBIAN_BRANCH" \
  --checklist "Selecciona lo que deseas instalar:" \
  20 60 10 \
  "${OPTIONS[@]}" \
  3>&1 1>&2 2>&3)

clear

# Ejecutar acciones según las elecciones
for CHOICE in $(echo "$CHOICES" | sed 's/"//g'); do
  case "$DEBIAN_BRANCH-$CHOICE" in
    "stable-1")
      echo "Instalando Comandos Base..."
      App.new BASE
      App.installApps BASE
      ;;
    "stable-2")
      echo "Instalando Tema de GRUB..."
      stable/install_grub_theme.sh "$THEME_SELECTED"
      stable/install_fuente_grub_tty.sh
      ;;  
    "stable-3")
      echo "Instalando KDE..."
      KDESApp.new KDESTABLE
      KDESApp.installApps KDESTABLE THEME_SELECTED
      ;;
    "stable-4")
      echo "Instalando Nvim/LazzyVim..."
      stable/install_nvim_src.sh
      stable/install_lazzyvim.sh
      ;;
    "stable-5")
      echo "Instalando tema RANGER..."
      cp -r "$RUTA_ORIGEN/config/ranger" "$HOME/.config"
      ;;
    "stable-6")
      echo "Instalando Wezterm..."
      stable/install_wezterm.sh
      mkdir -p "$HOME/.config/wezterm"
      cp -r "$RUTA_ORIGEN/config/wezterm" "$HOME/.config"
      ;;
    "stable-7")
      echo "Instalando FLAT APPS..."
      FlatApp.new FL
      FlatApp.installApps FL
      ;;
    "stable-8")
      echo "Creando Subvolúmenes..."
      stable/install_subvolumenes_debian.sh
      stable/config_snapper.sh
      stable/config_grub_btrfs.sh
      ;;
    "stable-9")
      echo "Instalando perfiles AppArmor..."
      stable/seguridad/crear_perfiles_apparmor.sh
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

echo "Personalización completada para Debian $DEBIAN_BRANCH"
