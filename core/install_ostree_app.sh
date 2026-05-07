#!/usr/bin/env bash
# INSTALACIÓN DE LAS APLICACIONES BASE PARA EL ENTORNO INMUTABLE CON OSTREE

set -euo pipefail

readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RUTA_ACTUAL/../config/constantes.sh"

CROWDSEC_REPO="/etc/yum.repos.d/crowdsec_crowdsec.repo"
CROWDSEC_REPO_URL="https://packagecloud.io/install/repositories/crowdsec/crowdsec/config_file.repo?os=fedora&dist=44"

# Detectar si estamos en Fedora Atomic/Kinoite/Silverblue
if ! command -v rpm-ostree &>/dev/null; then
    echo "Este script requiere rpm-ostree."
    exit 1
fi

REQUIERE_REINICIO=0

# ============================================================
# CROWDSEC REPOSITORY
# ============================================================

if [[ -f "$CROWDSEC_REPO" ]]; then
    echo "[OK] Repositorio de CrowdSec ya presente."
else
    echo "[INFO] Agregando repositorio de CrowdSec..."

    sudo curl -fsSL \
        -o "$CROWDSEC_REPO" \
        "$CROWDSEC_REPO_URL"

    echo "[OK] Repo CrowdSec agregado."

    REQUIERE_REINICIO=1
fi

# ============================================================
# SI SE AGREGÓ EL REPO -> ACTUALIZAR METADATOS Y REINICIAR
# ============================================================

if [[ "$REQUIERE_REINICIO" -eq 1 ]]; then
    echo "[INFO] Actualizando metadata OSTree..."

    sudo rpm-ostree upgrade

    MENSAJE="Se agregó el repositorio de CrowdSec.\n\nDebes reiniciar el sistema antes de continuar con la instalación de paquetes OSTree."

    if command -v kdialog &>/dev/null; then
        kdialog --title "Reinicio requerido" --msgbox "$MENSAJE"
    else
        echo -e "$MENSAJE"
    fi

    exit 0
fi

# ============================================================
# INSTALACIÓN DE PAQUETES
# ============================================================

sudo rpm-ostree install \
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
  glab

# ============================================================
# FINAL
# ============================================================

MENSAJE_FINAL="La instalación OSTree finalizó.\n\nDebes reiniciar el sistema para aplicar los cambios."

if command -v kdialog &>/dev/null; then
    kdialog --title "Reinicio requerido" --msgbox "$MENSAJE_FINAL"
else
    echo -e "$MENSAJE_FINAL"
fi
