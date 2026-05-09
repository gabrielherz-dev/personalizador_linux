#!/usr/bin/env bash
# INSTALACIÓN DE LAS APLICACIONES BASE PARA EL ENTORNO INMUTABLE CON OSTREE

set -uo pipefail

readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly RUTA_LOG="$RUTA_ACTUAL/../LOG"

source "$RUTA_ACTUAL/../config/constantes.sh"

LOG_ERRORES="${RUTA_LOG}/rpm-ostree-install-errors.log"

# Limpia log anterior
: > "$LOG_ERRORES"


# Lista de paquetes
PAQUETES=(
  gnupg2
  gnupg2-utils
  neovim
  ranger
  ca-certificates
  distrobox
  git
  wl-clipboard
  qemu-kvm
  libvirt
  virt-manager
  virt-viewer
  edk2-ovmf
  libvirt-daemon-config-network
  zsh
  fish
  dialog
  gum
  snapper
  rclone
  restic
  NetworkManager-openvpn-gnome
  NetworkManager-fortisslvpn
  NetworkManager-l2tp
  wireguard-tools
  openconnect
  gh
  jq
  yq
  act
  glab
)

echo "================================================="
echo "Verificando paquetes disponibles..."
echo "================================================="

PAQUETES_VALIDOS=()
PAQUETES_FALLIDOS=()

for paquete in "${PAQUETES[@]}"; do
    echo -n "Comprobando ${paquete}... "

    if rpm -q "$paquete" &>/dev/null; then
        echo "ya instalado"
        continue
    fi

    if rpm-ostree search "$paquete" &>/dev/null; then
        echo "OK"
        PAQUETES_VALIDOS+=("$paquete")
    else
        echo "FALLO"
        PAQUETES_FALLIDOS+=("$paquete")

        {
          echo "[$(date '+%Y-%m-%d %H:%M:%S')]"
          echo "Paquete no encontrado o inválido: $paquete"
          echo "--------------------------------------------"
        } >> "$LOG_ERRORES"
    fi
done

echo
echo "================================================="
echo "Instalando paquetes válidos..."
echo "================================================="

if [ ${#PAQUETES_VALIDOS[@]} -gt 0 ]; then
    rpm-ostree install "${PAQUETES_VALIDOS[@]}"
else
    echo "No hay paquetes válidos para instalar."
fi

echo
echo "================================================="
echo "Resumen"
echo "================================================="

echo "Paquetes válidos: ${#PAQUETES_VALIDOS[@]}"
echo "Paquetes fallidos: ${#PAQUETES_FALLIDOS[@]}"

if [ ${#PAQUETES_FALLIDOS[@]} -gt 0 ]; then
    echo
    echo "Paquetes con error:"
    printf ' - %s\n' "${PAQUETES_FALLIDOS[@]}"

    echo
    echo "Log de errores:"
    echo "$LOG_ERRORES"
fi
