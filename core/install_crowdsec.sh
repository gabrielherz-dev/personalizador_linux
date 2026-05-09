#!/usr/bin/env bash
# ============================================================
# CrowdSec + Firewall Bouncer en Fedora Kinoite/Silverblue
# ============================================================

set -euo pipefail

readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TOOLBOX_NAME="crowdsec"
readonly CONTAINER_IMAGE="docker.io/crowdsecurity/crowdsec:latest"

# ============================================================
# VERIFICACIONES INICIALES
# ============================================================

for cmd in toolbox podman systemctl; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "[ERROR] $cmd no está instalado."
        exit 1
    fi
done

# ============================================================
# LIMPIEZA PREVIA (RESET)
# ============================================================
echo "[INFO] Limpiando instalaciones anteriores..."

# Detener y eliminar servicio del bouncer si existe
sudo systemctl disable --now crowdsec-firewall-bouncer.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/crowdsec-firewall-bouncer.service

# Eliminar contenedor rootful de CrowdSec si existe
if sudo podman container exists crowdsec; then
    echo "[INFO] Eliminando contenedor 'crowdsec' existente..."
    sudo podman rm -f crowdsec
fi

# Eliminar directorios de configuración para empezar de cero
sudo rm -rf /var/lib/crowdsec /etc/crowdsec
sudo mkdir -p /var/lib/crowdsec /etc/crowdsec

echo "[OK] Limpieza completada."

# ============================================================
# CREAR TOOLBOX (OPCIONAL/ENTORNO)
# ============================================================
if toolbox list | grep -q "^${TOOLBOX_NAME} "; then
    echo "[OK] Toolbox '${TOOLBOX_NAME}' ya existe."
else
    echo "[INFO] Creando toolbox '${TOOLBOX_NAME}'..."
    toolbox create -y "${TOOLBOX_NAME}"
fi

# ============================================================
# FIREWALL (FIREWALLD / NFTABLES)
# ============================================================
echo "[INFO] Configurando firewalld..."

sudo systemctl enable --now firewalld

# Limpiar ipset previo si existe y crear uno nuevo
sudo firewall-cmd --permanent --delete-ipset=crowdsec-blacklists 2>/dev/null || true
sudo firewall-cmd --permanent --new-ipset=crowdsec-blacklists --type=hash:ip || true

sudo firewall-cmd --permanent \
  --add-rich-rule='rule source ipset="crowdsec-blacklists" drop' || true

sudo firewall-cmd --reload

# ============================================================
# CONFIGURACIÓN DE ADQUISICIÓN
# ============================================================
echo "[INFO] Creando acquis.yaml..."

sudo tee /etc/crowdsec/acquis.yaml >/dev/null <<EOF
filenames:
  - /var/log/secure
  - /var/log/auth.log
labels:
  type: syslog
---
source: journalctl
journalctl_filter:
  - "_SYSTEMD_UNIT=sshd.service"
labels:
  type: syslog
EOF

# ============================================================
# DESPLIEGUE DEL CONTENEDOR (ROOTFUL)
# ============================================================
echo "[INFO] Lanzando contenedor CrowdSec..."

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
  -v /var/lib/crowdsec:/var/lib/crowdsec \
  -v /etc/crowdsec:/etc/crowdsec \
  "${CONTAINER_IMAGE}"

echo "[INFO] Esperando a que el motor arranque..."
sleep 15

# ============================================================
# INSTALACIÓN DEL BOUNCER
# ============================================================
echo "[INFO] Configurando Firewall Bouncer..."

# Generar la API Key
BOUNCER_KEY=$(sudo podman exec crowdsec cscli bouncers add firewall-bouncer -o raw)

sudo tee /etc/crowdsec/bouncer.yaml >/dev/null <<EOF
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

# Crear y activar servicio del bouncer
sudo tee /etc/systemd/system/crowdsec-firewall-bouncer.service >/dev/null <<'EOF'
[Unit]
Description=CrowdSec Firewall Bouncer
After=network.target firewalld.service

[Service]
ExecStart=/usr/bin/podman exec crowdsec cs-firewall-bouncer -c /etc/crowdsec/bouncer.yaml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now crowdsec-firewall-bouncer.service

# ============================================================
# COLECCIONES Y VALIDACIÓN
# ============================================================
echo "[INFO] Instalando colecciones..."
sudo podman exec crowdsec cscli collections install crowdsecurity/linux crowdsecurity/sshd

echo "------------------------------------------------------------"
echo " ¡CrowdSec se ha reinstalado correctamente! "
echo "------------------------------------------------------------"
sudo podman exec crowdsec cscli status
