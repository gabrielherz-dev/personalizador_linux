# !/bin/bash
# Clase para la instalación de aplicaciones del sistema
#
#source App.class.sh
readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RUTA_ACTUAL/../config/constantes.sh"

declare -A FlatApp

FlatApp.new() {
  local self=$1
  #Declaro mi propio this como un arreglo global de propiedades
  declare -gA $self
  ##El equivalente a super() en otros lenguajes, heredo los atributos y métodos de mi clase padre
  #App.new "$self"
  #Creo un puntero para tratar el atributo
  declare -n rself="$self"
  #Borro los atributos de mi clase padre, solo me interesan los de esta clase hija
  unset self
  #rself["org.wezfurlong.wezterm"]="org.wezfurlong.wezterm"
  rself["org.flameshot.Flameshot"]="org.flameshot.Flameshot"
  rself["com.brave.Browser"]="com.brave.Browser"
  rself["md.obsidian.Obsidian"]="md.obsidian.Obsidian"
  rself["org.chromium.Chromium"]="org.chromium.Chromium"
  rself["org.telegram.desktop"]="org.telegram.desktop"
  rself["org.gimp.GIMP"]="org.gimp.GIMP"
  rself["org.kde.kolourpaint"]="org.kde.kolourpaint"
  rself["org.kde.okular"]="org.kde.okular"
  rself["org.keepassxc.KeePassXC"]="org.keepassxc.KeePassXC"
  rself["app.zen_browser.zen"]="app.zen_browser.zen"
  FlatApp.addRepos
}
FlatApp.addRepos() {
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}
# Métodos heredados
# INVOCACIÓN AL MÉTODO SUPER (PADRE)
FlatApp.installApps() {
  local self=$1
  declare -n ref="$self"
  for key in "${!ref[@]}"; do
    if FlatApp.checkInstall "${ref[$key]}"; then
      FlatApp.install "$key"
    fi
  done
  #  FlatApp.installConfig
}

#FlatApp.installConfig() {
#flatpak install flathub $1
#}

FlatApp.install() {
  # --noninteractive: evita cualquier prompt, instala lo necesario automáticamente
  flatpak install flathub --noninteractive $1 | tee -a $LOG_INSTALLATION
}

FlatApp.checkInstall() {
  #if flatpak info "$1" &>/dev/null; then
  if [[ -z $(flatpak info $1 | grep "*unspecified*") ]]; then
    echo true
  fi
}
