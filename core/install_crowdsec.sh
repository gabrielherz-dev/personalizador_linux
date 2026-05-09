#!/usr/bin/env bash

set -Eeuo pipefail

readonly CONTAINER_IMAGE="docker.io/crowdsecurity/crowdsec:latest"

echo "[INFO] Limpieza previa..."

# Detener bouncer y limpiar rastro
sudo systemctl stop crowdsec-firewall-bouncer.service 2>/dev/null || true
sudo systemctl disable crowdsec-firewall-bouncer.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/crowdsec-firewall-bouncer.service
sudo systemctl daemon-reload

# Eliminar contenedor
sudo podman rm -f crowdsec 2>/dev/null || true

# Limpiar Firewall (evitar warnings)
sudo firewall-cmd --permanent --remove-rich-rule='rule source ipset="crowdsec-blacklists" drop' 2>/dev/null || true
sudo firewall-cmd --permanent --delete-ipset=crowdsec-blacklists 2>/dev/null || true
sudo firewall-cmd --reload || true

# Limpiar y PRE-CREAR estructura de directorios
sudo rm -rf /var/lib/crowdsec /etc/crowdsec
sudo mkdir -p /var/lib/crowdsec/data  # CRÍTICO: Crear subdirectorio de datos
sudo mkdir -p /etc/crowdsec
sudo chmod -R 755 /var/lib/crowdsec /etc/crowdsec

echo "[INFO] Configurando firewalld..."
sudo systemctl enable --now firewalld
sudo firewall-cmd --permanent --new-ipset=crowdsec-blacklists --type=hash:ip
sudo firewall-cmd --permanent --add-rich-rule='rule source ipset="crowdsec-blacklists" drop'
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

# Aplicando corrección SELinux y montajes
sudo podman run -d \
  --name crowdsec \
  --restart unless-stopped \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  --security-opt label=disable \
  -v /var/log:/var/log:ro \
  -v /run/log/journal:/run/log/journal:ro \
  -v /etc/machine-id:/etc/machine-id:ro \
  -v /var/lib/crowdsec:/var/lib/crowdsec:Z \
  -v /etc/crowdsec:/etc/crowdsec:Z \
  "${CONTAINER_IMAGE}"

echo "[INFO] Esperando inicialización (puede tardar por descarga de GeoIP)..."

# Espera robusta: verifica si el proceso LAPI responde
n=0
until sudo podman exec crowdsec cscli lapi status >/dev/null 2>&1; do
    n=$((n+1))
    if [ $n -gt 30 ]; then
        echo "[ERROR] CrowdSec no inició a tiempo."
        sudo podman logs crowdsec
        exit 1
    fi
    sleep 2
done

echo "[INFO] Instalando colecciones..."
sudo podman exec crowdsec cscli collections install crowdsecurity/linux crowdsecurity/sshd

echo "[INFO] Creando bouncer..."
BOUNCER_KEY=$(sudo podman exec crowdsec cscli bouncers add firewall-bouncer -o raw)

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

echo "[INFO] Configurando servicio systemd para el bouncer..."
sudo tee /etc/systemd/system/crowdsec-firewall-bouncer.service >/dev/null <<'EOF'
[Unit]
Description=CrowdSec Firewall Bouncer
After=network.target firewalld.service

[Service]
ExecStart=/usr/bin/podman exec crowdsec cs-firewall-bouncer -c /etc/crowdsec/bouncer.yaml
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now crowdsec-firewall-bouncer.service

echo
echo "=================================================="
echo " CrowdSec instalado correctamente"
echo "=================================================="
echo "[INFO] Estadísticas del motor:"
sudo podman exec crowdsec cscli metrics
echo
echo "[INFO] Bouncers conectados:"
sudo podman exec crowdsec cscli bouncers list
