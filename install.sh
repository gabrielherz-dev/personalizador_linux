#!/bin/bash

# ==========================
# Personalizador de Fedora Kinoite
# ==========================

set -uo pipefail

readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Importar clases y scripts
source "$RUTA_ACTUAL/config/constantes.sh"
source "$RUTA_ACTUAL/core/FlatApp.class.sh"

# Validar que kdialog esté instalado
command -v kdialog >/dev/null 2>&1 || {
  echo "Se requiere el paquete 'kdialog'. Instálalo con: rpm-ostree install kdialog"
  exit 1
}

# Opciones para kdialog
OPTIONS=(
  "1" "Instalar Paquetes Ostree" "on"
  "2" "Instalar Nvim/LazzyVim" "on"
  "3" "Instalar Wallpapers" "off"
  "4" "Instalar Apps FLATPAK y VSCODE/Entorno dev" "off"
  "5" "Instalar Crowdsec" "on"
)

# Mostrar checklist
CHOICES=$(kdialog --title "Personalizador de KINOITE" \
  --checklist "Selecciona lo que deseas instalar:" \
  "${OPTIONS[@]}" \
  --separate-output)

# Cancelado
if [ $? -ne 0 ]; then
  echo "Instalación cancelada por el usuario."
  exit 0
fi

clear

# Ejecutar acciones
for CHOICE in $CHOICES; do
  case "$CHOICE" in

    "1")
      echo "Verificando actualizaciones OSTree..."

      # Ejecuta update y captura salida
      UPDATE_OUTPUT=$(rpm-ostree update 2>&1)
      UPDATE_EXIT_CODE=$?

      echo "$UPDATE_OUTPUT"

      # Si rpm-ostree falló
      if [ $UPDATE_EXIT_CODE -ne 0 ]; then
        kdialog --error "Error ejecutando rpm-ostree update"
        continue
      fi

      # Detecta si hubo cambios reales
      if echo "$UPDATE_OUTPUT" | grep -qiE "Upgraded:|Added:|Removed:|Downgraded:"; then

        kdialog --msgbox \
          "Se instalaron actualizaciones OSTree.\n\nEs necesario reiniciar el sistema."

        if kdialog --yesno "¿Deseas reiniciar ahora?"; then
          systemctl reboot
        else
          kdialog --msgbox \
            "Debes reiniciar manualmente para aplicar los cambios."
        fi

      else
        echo "Sistema actualizado. Ejecutando instalación OSTree..."
        "$RUTA_ACTUAL/core/install_ostree_app.sh"
      fi
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
      "$RUTA_ACTUAL/core/config_systemd_crowdsec.sh"
      ;;

    *)
      echo "Opción no reconocida: $CHOICE"
      ;;
  esac
done

# Mensaje final
kdialog --msgbox "Proceso completado."
