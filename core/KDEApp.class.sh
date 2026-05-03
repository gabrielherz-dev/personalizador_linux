#!/usr/bin/env bash
# Clase para la instalación de aplicaciones KDE

readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RUTA_ACTUAL/../config/constantes.sh"

declare -A KDEApp

KDEApp.new() {
  local self=$1
  declare -gA "$self"
  declare -n ref="$self"
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
#  ref["yast2"]="yast2 --version"
}


KDEApp.install() {
  sudo zypper install -y "$1" | tee -a "$LOG_INSTALLATION"
}

KDEApp.checkInstall() {
  [[ -n $(command -v "$1") ]]
}

KDEApp.installApps() {
  local self=$1
  declare -n ref="$self"
  for key in "${!ref[@]}"; do
    if ! KDEApp.checkInstall "${ref[$key]}"; then
      KDEApp.install "$key"
    fi
  done
}

KDEApp.installConfig() {
  sudo zypper install -t pattern kde_plasma

}
