#!/bin/bash

# ==========================
# Personalizador de Fedora Kinoite
# ==========================

readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Importar clases y scripts (Asegúrate de que estas rutas existan)
source "$RUTA_ACTUAL/config/constantes.sh"
source "$RUTA_ACTUAL/core/FlatApp.class.sh"

# Validar que kdialog esté instalado
command -v kdialog >/dev/null 2>&1 || {
  echo "Se requiere el paquete 'kdialog'. Instálalo con: rpm-ostree install kdialog"
  exit 1
}

# Opciones para kdialog (ID, Texto, Estado)
# NOTA: Ajusté los números para que coincidan con tu ciclo 'case' de abajo.
OPTIONS=(
  "1" "Instalar Paquetes Ostree" "on"
  "2" "Instalar Nvim/LazzyVim" "on"
  "3" "Instalar Wallpapers" "off"
  "4" "Instalar Apps FLATPAK y VSCODE/Entorno dev" "off"
  "5" "Instalar Crowdsec" "on"
)

# Mostrar el checklist con kdialog
# --separate-output devuelve una lista limpia de IDs seleccionados
CHOICES=$(kdialog --title "Personalizador de KINOITE" \
  --checklist "Selecciona lo que deseas instalar:" \
  "${OPTIONS[@]}" \
  --separate-output)

# Validar si el usuario presionó "Cancelar" o cerró la ventana
if [ $? -ne 0 ]; then
  echo "Instalación cancelada por el usuario."
  exit 0
fi

clear

# Ejecutar acciones según las elecciones
# kdialog con --separate-output devuelve los valores separados por saltos de línea,
# por lo que no es necesario usar 'sed' para quitar comillas.
for CHOICE in $CHOICES; do
  case "$CHOICE" in
    "1")
      echo "Instalando Paquetes Ostree..."
      "$RUTA_ACTUAL/core/install_ostree_app.sh"
      ;;
    "2")
      echo "Instalando Nvim/LazzyVim..."
      "$RUTA_ACTUAL/core/install_lazzyvim.sh"
      ;;
    "3")
      echo "Instalando Wallpapers..."
      mkdir -p "$HOME/.local/share/wallpapers"
      cp -r "$RUTA_ACTUAL/config/wallpapers/"* "$HOME/.local/share/wallpapers"
      ;;
    "4")
      echo "Instalando FLATPAK APPS..."
      FlatApp.new FL
      FlatApp.installApps FL
      echo "Instalando entorno de desarrollo toolbx para VSCODE de FLATPAK"
      "$RUTA_ACTUAL/core/install_contenedor_dev_toolbx.sh"
      ;;
     "5")
      echo "Instalando Crowdsec..."
      "$RUTA_ACTUAL/core/install_crowdsec.sh"

      ;;
    *)
      echo "Opción no reconocida: $CHOICE"
      ;;
  esac
done

# En lugar de un 'echo' en la terminal, lanzamos un mensaje gráfico final
kdialog --msgbox "Personalización completada para KINOITE" --title "Éxito"
