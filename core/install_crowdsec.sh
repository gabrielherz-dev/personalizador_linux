#!/usr/bin/env bash

set -Eeuo pipefail

readonly CONTAINER_IMAGE="docker.io/crowdsecurity/crowdsec:latest"

echo "[INFO] Limpieza previa..."

sudo systemctl stop crowdsec-firewall-bouncer.service 2>/dev/null || true
sudo systemctl disable crowdsec-firewall-bouncer.service 2>/dev/null || true

sudo rm -f /etc/systemd/system/crowdsec-firewall-bouncer.service

sudo podman rm -f crowdsec 2>/dev/null || true

sudo firewall-cmd --permanent \
  --remove-rich-rule='rule source ipset="crowdsec-blacklists" drop' \
  2>/dev/null || true

sudo firewall-cmd --permanent \
  --delete-ipset=crowdsec-blacklists \
  2>/dev/null || true

sudo firewall-cmd --reload || true

sudo rm -rf /var/lib/crowdsec
sudo rm -rf /etc/crowdsec

sudo mkdir -p /var/lib/crowdsec
sudo mkdir -p /etc/crowdsec

echo "[INFO] Configurando firewalld..."

sudo systemctl enable --now firewalld

sudo firewall-cmd --permanent \
  --new-ipset=crowdsec-blacklists \
  --type=hash:ip

sudo firewall-cmd --permanent \
  --add-rich-rule='rule source ipset="crowdsec-blacklists" drop'

sudo firewall-cmd --reload

echo "[INFO] Creando acquis.yaml..."

sudo tee /etc/crowdsec/acquis.yaml >/dev/null <<EOF
filenames:
  - /var/log/secure
labels:
  type: syslog
---
source: journalctl
journalctl_filter:
  - "_SYSTEMD_UNIT=sshd.service"
labels:
  type: syslog
EOF

echo "[INFO] Lanzando CrowdSec..."

sudo podman run -d \
  --name crowdsec \
  --restart unless-stopped \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  --security-opt label=disable \
  -v /var/log:/var/log:ro,Z \
  -v /run/log/journal:/run/log/journal:ro,Z \
  -v /etc/machine-id:/etc/machine-id:ro,Z \
  -v /var/lib/crowdsec:/var/lib/crowdsec:Z \
  -v /etc/crowdsec:/etc/crowdsec:Z \
  "${CONTAINER_IMAGE}"

echo "[INFO] Esperando inicialización de CrowdSec..."

until sudo podman exec crowdsec cscli lapi status >/dev/null 2>&1; do
    sleep 2

    if ! sudo podman ps --format '{{.Names}}' | grep -q '^crowdsec$'; then
        echo "[ERROR] CrowdSec se detuvo."
        sudo podman logs crowdsec
        exit 1
    fi
done

echo "[INFO] Instalando colecciones..."

sudo podman exec crowdsec \
  cscli collections install crowdsecurity/linux

sudo podman exec crowdsec \
  cscli collections install crowdsecurity/sshd

echo "[INFO] Creando bouncer..."

BOUNCER_KEY=$(sudo podman exec crowdsec \
  cscli bouncers add firewall-bouncer -o raw)

sudo tee /etc/crowdsec/bouncer.yaml >/dev/null <<EOF
mode: nftables
api_url: http://127.0.0.1:8080/
api_key: ${BOUNCER_KEY}

nftables:
  ipv4:
    enabled: true

  ipv6:
    enabled: true
EOF

echo "[INFO] Iniciando firewall bouncer..."

sudo podman exec -d crowdsec \
  cs-firewall-bouncer -c /etc/crowdsec/bouncer.yaml

echo
echo "=================================================="
echo " CrowdSec instalado correctamente"
echo "=================================================="

sudo podman exec crowdsec cscli status
