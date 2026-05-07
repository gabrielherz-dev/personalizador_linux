
#!/usr/bin/env bash
#INSTALACIÓN DE LAS APLICACIONES BASE PARA EL ENTORNO INMUTABLE CON OSTREE
readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RUTA_ACTUAL/../config/constantes.sh"

# Agrega el Repositorio de crowdsec
curl -s https://install.crowdsec.net | sudo bash

# Actualiza e instala los metadatos de los repositorios agregados
rpm-ostree upgrade

# Editor, gestor de ficheros y directorios, gestor de claves públicas y certificados digitales
# También se instala quemu, su gestor de redes, etc y zsh además de fish
# VPNs PROTON, WIREGUARD, FORTI, etc
# gh github client
# para github : gh (CLI  y automatización github),runner local = act, API parsing json y yaml ?jq yq ,  
# para gitlab: glab
rpm-ostree install \
  neovim \
  ranger \
  gnupg2 \
  gnupg2-utils \
  ca-certificates \
  distrobox \
  git \
  wl-clipboard \
  qemu-kvm \
  libvirt \
  virt-manager \
  virt-viewer \
  edk2-ovmf \
  libvirt-daemon-config-network \
  zsh \
  fish \
  util-linux-user \
  crowdsec \
  crowdsec-firewall-bouncer-nftables \
  dialog \
  gum \
  snapper \
  rclone \
  restic \
  NetworkManager-openvpn-gnome \
  NetworkManager-fortisslvpn \
  NetworkManager-l2tp \
  wireguard-tools \
  openconnect \
  gh \
  jq \
  yq \
  act \
  glab \

