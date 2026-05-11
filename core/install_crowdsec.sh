#!/usr/bin/env bash

set -Eeuo pipefail

readonly CONTAINER_IMAGE="docker.io/crowdsecurity/crowdsec:latest"
readonly BOUNCER_IMAGE="docker.io/crowdsecurity/crowdsec-bouncer-firewall:latest"

echo "[INFO] Limpieza previa..."

# Detener bouncer/servicios antiguos si existían
sudo systemctl stop crowdsec-firewall-bouncer.service 2>/dev/null || true
sudo systemctl disable crowdsec-firewall-bouncer.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/crowdsec-firewall-bouncer.service
sudo systemctl daemon-reload

# Eliminar contenedores previos
sudo podman rm -f crowdsec crowdsec-bouncer 2>/dev/null || true

# Limpiar Firewall 
sudo firewall-cmd --permanent --remove-rich-rule='rule source ipset="crowdsec-blacklists" drop' 2>/dev/null || true
sudo firewall-cmd --permanent --delete-ipset=crowdsec-blacklists 2>/dev/null || true
sudo firewall-cmd --reload || true

# Limpiar directorios
sudo rm -rf /var/lib/crowdsec /etc/crowdsec

echo "[INFO] Extrayendo configuración por defecto de CrowdSec..."
# CRÍTICO: Sacamos los ficheros base de la imagen antes de montar el volumen vacío
sudo podman create --name temp-cs "${CONTAINER_IMAGE}"
sudo mkdir -p /etc/crowdsec /var/lib/crowdsec
sudo podman cp temp-cs:/etc/crowdsec/. /etc/crowdsec/
sudo podman cp temp-cs:/var/lib/crowdsec/. /var/lib/crowdsec/
sudo podman rm temp-cs

# Permisos para SELinux/Podman
sudo chmod -R 755 /var/lib/crowdsec /etc/crowdsec

echo "[INFO] Configurando firewalld..."
sudo systemctl enable --now firewalld
sudo firewall-cmd --permanent --new-ipset=crowdsec-blacklists --type=hash:ip
sudo firewall-cmd --permanent --add-rich-rule='rule source ipset="crowdsec-blacklists" drop'
sudo firewall-cmd --reload

echo "[INFO] Creando acquis.yaml personalizado..."
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

echo "[INFO] Lanzando motor principal de CrowdSec..."
sudo podman run -d \
  --name crowdsec \
  --restart unless-stopped \
  --network host \
  --security-opt label=disable \
  -v /var/log:/var/log:ro \
  -v /run/log/journal:/run/log/journal:ro \
  -v /etc/machine-id:/etc/machine-id:ro \
  -v /var/lib/crowdsec:/var/lib/crowdsec:Z \
  -v /etc/crowdsec:/etc/crowdsec:Z \
  "${CONTAINER_IMAGE}"

echo "[INFO] Esperando inicialización del LAPI..."
n=0
until sudo podman exec crowdsec cscli lapi status >/dev/null 2>&1; do
    n=$((n+1))
    if [ $n -gt 30 ]; then
        echo "[ERROR] CrowdSec no inició a tiempo. Logs:"
        sudo podman logs crowdsec
        exit 1
    fi
    sleep 2
done

echo "[INFO] Instalando colecciones..."
sudo podman exec crowdsec cscli collections install crowdsecurity/linux crowdsecurity/sshd

# Reiniciamos para que aplique las colecciones recién instaladas
sudo podman restart crowdsec
sleep 3

echo "[INFO] Creando token para el bouncer..."
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

echo "[INFO] Lanzando contenedor dedicado para el Bouncer..."
sudo podman run -d \
  --name crowdsec-bouncer \
  --restart unless-stopped \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  -v /etc/crowdsec/bouncer.yaml:/etc/crowdsec/bouncer.yaml:ro \
  "${BOUNCER_IMAGE}"

echo
echo "=================================================="
echo " CrowdSec instalado correctamente"
echo "=================================================="
echo "[INFO] Estadísticas del motor:"
sudo podman exec crowdsec cscli metrics
echo
echo "[INFO] Bouncers conectados:"
sudo podman exec crowdsec cscli bouncers list
