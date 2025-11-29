#!/bin/bash

# ==========================
# Personalizador de Debian
# ==========================
#

readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Importar clases y scripts  debian stable
source "$RUTA_ACTUAL/config/constantes.sh"
source "$RUTA_ACTUAL/testing/GnomeApp.class.sh"
# Importar clases y scripts  debian testing que en su mayoría sirven para stable
source "$RUTA_ACTUAL/testing/App.class.sh"
source "$RUTA_ACTUAL/testing/I3wmApp.class.sh"
source "$RUTA_ACTUAL/testing/FlatApp.class.sh"
source "$RUTA_ACTUAL/testing/LightdmApp.class.sh"
source "$RUTA_ACTUAL/testing/KDEApp.class.sh"

# Importar clases y scripts  debian stable
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
  --backtitle "Selector de personalización de Debian" \
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
    1 "Instalar POP-SHELL para GNOME (ejecutar en sesión de GNOME" off
    2 "Instalar Tema KDE (luego de iniciar sesión)" off
    3 "Instalar KDE" off
    4 "Instalar LazzyVim" off
    5 "Instalar RANGER" off
    6 "Instalar Wezterm" off
    7 "Instalar XFCE4 complementos" off
    8 "Instalar XFCE4" on
    9 "Instalar Lanzador Albert" off
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
  OPTIONS=(
    1 "Instalar APP" on
    2 "Instalar i3wm" off
    3 "Instalar GRUB" on
    4 "Instalar Ahorro de batería" off
    5 "Instalar LightDM" off
    6 "Instalar FLATPAK" on
    7 "Crear Subvolumenes" off
    8 "Instalar perfiles AppArmour" off
    9 "Instalar GNOME" off
    10 "Instalar KDE" on
    11 "Instalar Tema KDE (luego de iniciar sesión)" off
    12 "Instalar ULAUNCHER (Debian 13)" off
    13 "Instalar tema ULAUNCHER (Debian 13)" off
  )
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
    # Se verifica que no sea root (su su - sudo)  porque los extensions de gnome se instalan sin ser root, al igual que sus configuraciones, para evitar conflictos con dconf
    if [[ ! $EUID -ne 0 ]]; then
      echo "Esta opción no puede ejecutarse con privilegios de superusuario."

      exit 1
    fi

    echo "Instalando POP-SHELL para GNOME con Keybindings..."
    # sudo apt install -y gnome-core gdm3
    stable/gnome_keybindings/install.sh
    ;;
  "stable-2")
    # Se verifica que no sea root (su su - sudo)  porque los extensions de gnome se instalan sin ser root, al igual que sus configuraciones, para evitar conflictos con dconf
    if [[ ! $EUID -ne 0 ]]; then
      echo "Esta opción no puede ejecutarse con privilegios de superusuario."

      exit 1
    fi
    echo "Instalando tema KDE, si no se ha iniciado sesión por primera vez, no se cargará..."
    install_theme_KDE.sh
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
    #		# Se verifica que no sea root (su su - sudo)  porque los extensions de gnome se instalan sin ser root, al igual que sus configuraciones, para evitar conflictos con dconf
    #		if [[ ! $EUID -ne 0 ]]; then
    #			echo "Esta opción no puede ejecutarse con privilegios de superusuario."
    #			exit 1
    #		fi
    echo "instalando personalización para XFCE4, debe iniciar sesión gráfica para ello..."
    stable/XFCE4/install_shortcuts_xfce.sh
    stable/XFCE4/change_cursor_size.sh
    stable/XFCE4/change_font_xfce.sh 14
    stable/XFCE4/install_xfce_wallpaper.sh "/usr/share/wallpapers/wallpaper_debian_principal.jpg"
    #Tlling window cortile
    stable/XFCE4/install_cortile.sh
    stable/XFCE4/enum_workspaces.sh
    stable/XFCE4/hide_title.sh
    stable/XFCE4/remove_icons_launcher.sh
    ;;
  "stable-8")
    echo "Instalando XFCE4 ..."
    stable/XFCE4/install_xfce.sh
    stable/XFCE4/install_albert_launcher.sh
    stable/XFCE4/uninstall.sh
    ;;
  "stable-9")
    echo "Instalando Lanzador Albert ..."
    stable/XFCE4/install_albert_launcher.sh
    ;;

  "testing-1")
    echo "Instalando Comandos Base..."
    App.new BASE
    App.installApps BASE
    ;;
  "testing-2")
    echo "Instalando I3WM..."
    I3wmApp.new I3wmApp
    I3wmApp.installApps I3wmApp "$THEME_SELECTED"
    #    I3wmApp.installConfig I3wmApp THEME_SELECTED
    ;;
  "testing-3")
    echo "Instalando Tema de GRUB..."
    testing/install_grub_theme.sh "$THEME_SELECTED"
    testing/install_fuente_grub_tty.sh
    testing/install_fuentes_initramfs_tty.sh
    ;;
  "testing-4")
    echo "Instalando Ahorro de Batería..."
    testing/install_battery_save.sh
    ;;
  "testing-5")
    echo "Instalando LightDM..."
    LightdmApp.new LightDM
    LightdmApp.installConfig LightDM "$THEME_SELECTED"
    ;;
  "testing-6")
    echo "Instalando FLAT APPS..."
    FlatApp.new FL
    FlatApp.installApps FL
    ;;
  "testing-7")
    echo "Creando Subvolúmenes..."
    testing/install_subvolumenes_debian.sh
    # testing/crear_subvols.sh
    ;;
  "testing-8")
    echo "Instalando perfiles AppArmor..."
    testing/seguridad/crear_perfiles_apparmor.sh
    # sudo apt install apparmor-profiles apparmor-utils
    ;;
  "testing-9")
    echo "Instalando GNOME..."
    GnomeApp.new GN
    GnomeApp.installApps GN
    GnomeApp.installConfig GN
    ;;
  "testing-10")
    echo "Instalando KDE..."
    KDEApp.new KDE
    KDEApp.installApps KDE "$THEME_SELECTED"
    ;;
  "testing-11")
    echo "Instalando tema KDE, si no se ha iniciado sesión por primera vez, no se cargará..."
    install_theme_KDE.sh
    ;;
  "testing-12")
    echo "Instalando ulauncher..."
    testing/install_ulauncher.sh
    ;;
  "testing-13")
    # Se verifica que no sea root (su su - sudo)  porque los extensions de gnome se instalan sin ser root, al igual que sus configuraciones, para evitar conflictos con dconf
    #    if [[ ! $EUID -ne 0 ]]; then
    #      echo "Esta opción no puede ejecutarse con privilegios de superusuario."
    #      exit 1
    #    fi
    echo "Instalando tema de ulauncher..."
    testing/install_ulauncher_theme.sh
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
