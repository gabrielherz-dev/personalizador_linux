#!/usr/bin/env bash

set -Eeuo pipefail

readonly CONTAINER_NAME="crowdsec"
readonly BOUNCER_CONTAINER_NAME="crowdsec-firewall-bouncer"
readonly CONTAINER_IMAGE="docker.io/crowdsecurity/crowdsec:latest"
readonly BOUNCER_IMAGE="docker.io/crowdsecurity/firewall-bouncer:latest"

echo "[INFO] =================================================="
echo "[INFO] CrowdSec & Firewall Bouncer Installer (Kinoite)"
echo "[INFO] =================================================="

# ============================================================
# LIMPIEZA PREVIA
# ============================================================
echo "[INFO] Limpiando instalación previa..."

# Detener servicio antiguo si existe
sudo systemctl stop crowdsec-firewall-bouncer.service 2>/dev/null || true
sudo systemctl disable crowdsec-firewall-bouncer.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/crowdsec-firewall-bouncer.service
sudo systemctl daemon-reload
sudo systemctl reset-failed

# Eliminar contenedores previos
sudo podman rm -f "${CONTAINER_NAME}" 2>/dev/null || true
sudo podman rm -f "${BOUNCER_CONTAINER_NAME}" 2>/dev/null || true

# Limpiar reglas manuales de firewalld (ya no son necesarias, el bouncer usa nftables directo)
sudo firewall-cmd --permanent --remove-rich-rule='rule source ipset="crowdsec-blacklists" drop' 2>/dev/null || true
sudo firewall-cmd --permanent --delete-ipset=crowdsec-blacklists 2>/dev/null || true
sudo firewall-cmd --reload || true

# Limpiar archivos viejos
sudo rm -rf /var/lib/crowdsec
sudo rm -f /etc/crowdsec-acquis.yaml
sudo rm -f /etc/crowdsec-bouncer.yaml

# Crear el directorio correcto para la base de datos
sudo mkdir -p /var/lib/crowdsec/data

# ============================================================
# ACQUIS.YAML (Solo Journald para Kinoite)
# ============================================================
echo "[INFO] Creando acquis.yaml..."

sudo tee /etc/crowdsec-acquis.yaml >/dev/null <<'EOF'
source: journalctl
journalctl_filter:
  - "_SYSTEMD_UNIT=sshd.service"
labels:
  type: syslog
EOF

# ============================================================
# DESCARGAR IMÁGENES
# ============================================================
echo "[INFO] Descargando imágenes de CrowdSec..."

sudo podman pull "${CONTAINER_IMAGE}"
sudo podman pull "${BOUNCER_IMAGE}"

# ============================================================
# CONTENEDOR PRINCIPAL (CROWDSEC)
# ============================================================
echo "[INFO] Lanzando contenedor principal de CrowdSec..."

sudo podman run -d \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  --network host \
  --security-opt label=disable \
  -v /var/log:/var/log:ro \
  -v /run/log/journal:/run/log/journal:ro \
  -v /etc/machine-id:/etc/machine-id:ro \
  -v /var/lib/crowdsec/data:/var/lib/crowdsec/data \
  -v /etc/crowdsec-acquis.yaml:/etc/crowdsec/acquis.d/kinoite.yaml:ro \
  "${CONTAINER_IMAGE}"

# ============================================================
# ESPERA ROBUSTA
# ============================================================
echo "[INFO] Esperando inicialización de CrowdSec..."

n=0
until sudo podman exec "${CONTAINER_NAME}" cscli lapi status >/dev/null 2>&1; do
    n=$((n+1))

    if ! sudo podman ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo
        echo "[ERROR] CrowdSec se detuvo inesperadamente."
        echo "--------------------------------------------------"
        sudo podman logs "${CONTAINER_NAME}"
        echo "--------------------------------------------------"
        exit 1
    fi

    if [ "$n" -gt 60 ]; then
        echo
        echo "[ERROR] Timeout esperando CrowdSec."
        sudo podman logs "${CONTAINER_NAME}"
        exit 1
    fi
    sleep 2
done

echo "[OK] CrowdSec inicializado correctamente."

# ============================================================
# COLECCIONES
# ============================================================
echo "[INFO] Instalando colecciones..."
sudo podman exec "${CONTAINER_NAME}" cscli collections install crowdsecurity/linux
sudo podman exec "${CONTAINER_NAME}" cscli collections install crowdsecurity/sshd

# ============================================================
# API KEY & CONFIGURACIÓN DEL BOUNCER
# ============================================================
echo "[INFO] Creando API key del bouncer..."
BOUNCER_KEY=$(sudo podman exec "${CONTAINER_NAME}" cscli bouncers add firewall-bouncer -o raw)

echo "[INFO] Creando configuración del bouncer..."
sudo tee /etc/crowdsec-bouncer.yaml >/dev/null <<EOF
mode: nftables
api_url: http://127.0.0.1:8080/
api_key: ${BOUNCER_KEY}
nftables:
  ipv4:
    enabled: true
    set-only: false
  ipv6:
    enabled: true
    set-only: false
EOF

# ============================================================
# CONTENEDOR DEL BOUNCER (Sustituye al servicio systemd)
# ============================================================
echo "[INFO] Lanzando contenedor del Firewall Bouncer..."

sudo podman run -d \
  --name "${BOUNCER_CONTAINER_NAME}" \
  --restart unless-stopped \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  --security-opt label=disable \
  -v /lib/modules:/lib/modules:ro \
  -v /etc/crowdsec-bouncer.yaml:/etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml:ro \
  "${BOUNCER_IMAGE}"

# ============================================================
# VALIDACIÓN
# ============================================================
echo
echo "=================================================="
echo " CrowdSec y Bouncer instalados correctamente"
echo "=================================================="
echo

echo "[INFO] Contenedores en ejecución:"
sudo podman ps -f name=crowdsec

echo
echo "[INFO] Estado CrowdSec:"
sudo podman exec "${CONTAINER_NAME}" cscli status

echo
echo "[INFO] Bouncers registrados:"
sudo podman exec "${CONTAINER_NAME}" cscli bouncers list
