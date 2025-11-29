#!/usr/bin/env bash
# Clase para la instalación de aplicaciones del sistema

readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RUTA_ACTUAL/../config/constantes.sh"

declare -A App

App.new() {
  local self=$1
  declare -gA "$self"
  declare -n ref="$self"
  ref["cifs-utils"]="mount.cifs"
  ref["neovim"]="nvim"
  ref["firefox-esr"]="firefox-esr"
  ref["git"]="git"
  ref["unzip"]="unzip"
  ref["curl"]="curl"
  ref["bc"]="bc"
  ref["nodejs"]="node"
  ref["npm"]="npm"
  ref["dconf-cli"]="dconf"
  ref["flatpak"]="flatpak list"
  ref["make"]="make"
  ref["apparmor-utils"]="aa-enforce"
  ref["curl"]="curl"
  ref["ranger"]="ranger"
  #Para instalación de cortile
  ref["wget"]="wget"
  ref["jq"]="jq"
  ref["tar"]="tar"
  #Para instalación de albert launcher
  ref["curl"]="curl"
  #Para claves público/privadas, sobretodo para el repositorio de albert
  ref["gnupg"]="gnupg"
  #Certificados digitales , también para albert launcher
  ref["ca-certificates"]="ca-certificates"

  if [[ $EUID -ne 0 ]]; then
    echo "Este script necesita privilegios de superusuario."
    exit 1
  fi

  #cp config/.dialogrc "$RUTA_ORIGEN/"
  mkdir -vp "$TARGET_HOME/.config/wezterm"
  cp "$RUTA_ACTUAL/config/wezterm.lua" "$TARGET_HOME/.config/wezterm/wezterm.lua"
  App.installTerminal
}

#App.addRepos() {
#  curl -fsSL https://apt.wezfurlong.org/wezfurlong.gpg | tee /usr/share/keyrings/wezfurlong-archive-keyring.gpg >/dev/null
#  echo "deb [signed-by=/usr/share/keyrings/wezfurlong-archive-keyring.gpg] https://apt.wezfurlong.org/ stable main" | sudo tee /etc/apt/sources.list.d/wezfurlong.list
#  apt update
#}
# Instalación de Wezterm
App.installTerminal() {
  curl -LO https://github.com/wezterm/wezterm/releases/download/20240203-110809-5046fc22/wezterm-20240203-110809-5046fc22.Ubuntu22.04.deb
  apt install -y ./wezterm-20240203-110809-5046fc22.Ubuntu22.04.deb
}

App.install() {
  apt install -y "$1" | tee -a "$LOG_INSTALLATION"
}

App.checkInstall() {
  [[ -n $(command -v "$1") ]]
}

App.installApps() {
  local self=$1
  declare -n ref="$self"
  for key in "${!ref[@]}"; do
    if ! App.checkInstall "${ref[$key]}"; then
      App.install "$key"
    fi
  done
}

App.installConfig() {
  #  echo "Config adicional (sobrescribir en subclase si se desea)"
  #  Instalación de Typescript en NODEJS
  if ! App.checkInstall "npm"; then
    npm install -g typescript
  fi
}
