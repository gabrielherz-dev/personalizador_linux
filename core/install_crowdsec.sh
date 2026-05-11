#!/usr/bin/env bash

set -Eeuo pipefail

readonly CONTAINER_NAME="crowdsec"
readonly CONTAINER_IMAGE="docker.io/crowdsecurity/crowdsec:latest"

echo "[INFO] =================================================="
echo "[INFO] Limpieza previa"
echo "[INFO] =================================================="

# ------------------------------------------------------------
# SYSTEMD
# ------------------------------------------------------------

sudo systemctl stop crowdsec-firewall-bouncer.service 2>/dev/null || true
sudo systemctl disable crowdsec-firewall-bouncer.service 2>/dev/null || true

sudo rm -f /etc/systemd/system/crowdsec-firewall-bouncer.service

sudo systemctl daemon-reload
sudo systemctl reset-failed

# ------------------------------------------------------------
# PODMAN
# ------------------------------------------------------------

sudo podman rm -f "${CONTAINER_NAME}" 2>/dev/null || true

# ------------------------------------------------------------
# FIREWALLD
# ------------------------------------------------------------

sudo firewall-cmd --permanent \
  --remove-rich-rule='rule source ipset="crowdsec-blacklists" drop' \
  2>/dev/null || true

sudo firewall-cmd --permanent \
  --delete-ipset=crowdsec-blacklists \
  2>/dev/null || true

sudo firewall-cmd --reload || true

# ------------------------------------------------------------
# DIRECTORIOS
# ------------------------------------------------------------

sudo rm -rf /var/lib/crowdsec
sudo rm -rf /etc/crowdsec

sudo mkdir -p /var/lib/crowdsec
sudo mkdir -p /etc

sudo chmod 755 /var/lib/crowdsec

# ------------------------------------------------------------
# FIREWALLD
# ------------------------------------------------------------

echo "[INFO] Configurando firewalld..."

sudo systemctl enable --now firewalld

sudo firewall-cmd --permanent \
  --new-ipset=crowdsec-blacklists \
  --type=hash:ip

sudo firewall-cmd --permanent \
  --add-rich-rule='rule source ipset="crowdsec-blacklists" drop'

sudo firewall-cmd --reload

# ------------------------------------------------------------
# ACQUIS
# ------------------------------------------------------------

echo "[INFO] Creando acquis.yaml..."

sudo tee /etc/crowdsec-acquis.yaml >/dev/null <<'EOF'
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

# ------------------------------------------------------------
# CONTENEDOR
# ------------------------------------------------------------

echo "[INFO] Lanzando contenedor CrowdSec..."

sudo podman pull "${CONTAINER_IMAGE}"

sudo podman run -d \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  --security-opt label=disable \
  -v /var/log:/var/log:ro,Z \
  -v /run/log/journal:/run/log/journal:ro,Z \
  -v /etc/machine-id:/etc/machine-id:ro,Z \
  -v /var/lib/crowdsec:/var/lib/crowdsec:Z \
  -v /etc/crowdsec-acquis.yaml:/etc/crowdsec/acquis.yaml:ro,Z \
  "${CONTAINER_IMAGE}"

# ------------------------------------------------------------
# ESPERA ROBUSTA
# ------------------------------------------------------------

echo "[INFO] Esperando inicialización de CrowdSec..."

n=0

until sudo podman exec "${CONTAINER_NAME}" \
  cscli lapi status >/dev/null 2>&1; do

    n=$((n+1))

    # ¿El contenedor murió?
    if ! sudo podman ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo
        echo "[ERROR] El contenedor CrowdSec se detuvo."
        echo
        echo "[INFO] Logs del contenedor:"
        echo "--------------------------------------------------"
        sudo podman logs "${CONTAINER_NAME}"
        echo "--------------------------------------------------"
        exit 1
    fi

    if [ "$n" -gt 60 ]; then
        echo
        echo "[ERROR] Timeout esperando CrowdSec."
        echo
        sudo podman logs "${CONTAINER_NAME}"
        exit 1
    fi

    sleep 2
done

echo "[OK] CrowdSec inicializado."

# ------------------------------------------------------------
# COLECCIONES
# ------------------------------------------------------------

echo "[INFO] Instalando colecciones..."

sudo podman exec "${CONTAINER_NAME}" \
  cscli collections install crowdsecurity/linux

sudo podman exec "${CONTAINER_NAME}" \
  cscli collections install crowdsecurity/sshd

# ------------------------------------------------------------
# BOUNCER
# ------------------------------------------------------------

echo "[INFO] Creando API key del bouncer..."

BOUNCER_KEY=$(
sudo podman exec "${CONTAINER_NAME}" \
  cscli bouncers add firewall-bouncer -o raw
)

sudo tee /etc/crowdsec-bouncer.yaml >/dev/null <<EOF
mode: nftables

api_url: http://127.0.0.1:8080/

api_key: ${BOUNCER_KEY}

nftables:
  ipv4:
    enabled: true

  ipv6:
    enabled: true
EOF

# ------------------------------------------------------------
# SYSTEMD BOUNCER
# ------------------------------------------------------------

echo "[INFO] Configurando servicio systemd..."

sudo tee /etc/systemd/system/crowdsec-firewall-bouncer.service >/dev/null <<'EOF'
[Unit]
Description=CrowdSec Firewall Bouncer
After=network-online.target firewalld.service
Requires=firewalld.service

[Service]
Type=simple
User=root

ExecStartPre=/usr/bin/sleep 10

ExecStart=/usr/bin/podman exec crowdsec \
  cs-firewall-bouncer \
  -c /etc/crowdsec-bouncer.yaml

Restart=always
RestartSec=15

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

sudo systemctl enable --now crowdsec-firewall-bouncer.service

# ------------------------------------------------------------
# VALIDACIÓN
# ------------------------------------------------------------

echo
echo "=================================================="
echo " CrowdSec instalado correctamente"
echo "=================================================="
echo

echo "[INFO] Estado del contenedor:"
sudo podman ps

echo
echo "[INFO] Estado CrowdSec:"
sudo podman exec "${CONTAINER_NAME}" cscli status

echo
echo "[INFO] Métricas:"
sudo podman exec "${CONTAINER_NAME}" cscli metrics

echo
echo "[INFO] Bouncers:"
sudo podman exec "${CONTAINER_NAME}" cscli bouncers list

echo
echo "[INFO] Servicio systemd:"
systemctl status crowdsec-firewall-bouncer.service --no-pager

echo
echo "[OK] Instalación finalizada."
