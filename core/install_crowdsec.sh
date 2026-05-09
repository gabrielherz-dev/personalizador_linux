#!/usr/bin/env bash
# ============================================================
# CrowdSec + Firewall Bouncer en Fedora Kinoite/Silverblue
# usando Toolbox + Podman
# ============================================================

set -euo pipefail

readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly RUTA_LOG="$RUTA_ACTUAL/../LOG"
TOOLBOX_NAME="crowdsec"
CONTAINER_IMAGE="docker.io/crowdsecurity/crowdsec:latest"

# ============================================================
# VERIFICACIONES
# ============================================================

if ! command -v toolbox &>/dev/null; then
    echo "[ERROR] toolbox no está instalado."
    exit 1
fi

if ! command -v podman &>/dev/null; then
    echo "[ERROR] podman no está instalado."
    exit 1
fi

if ! command -v systemctl &>/dev/null; then
    echo "[ERROR] systemd no disponible."
    exit 1
fi

echo "[OK] Entorno validado."

# ============================================================
# CREAR TOOLBOX SI NO EXISTE
# ============================================================
# Nota: Si el objetivo de CrowdSec es correr 100% como un servicio
# Podman rootful, el entorno Toolbox no se está utilizando realmente
# para este servicio y podría omitirse. Lo mantenemos según tu diseño.

if toolbox list | grep -q "^${TOOLBOX_NAME} "; then
    echo "[OK] Toolbox '${TOOLBOX_NAME}' ya existe."
else
    echo "[INFO] Creando toolbox '${TOOLBOX_NAME}'..."
    toolbox create "${TOOLBOX_NAME}"
fi

# ============================================================
# DIRECTORIOS PERSISTENTES
# ============================================================

sudo mkdir -p /var/lib/crowdsec
sudo mkdir -p /etc/crowdsec

# ============================================================
# FIREWALL
# ============================================================

echo "[INFO] Configurando firewalld..."

sudo systemctl enable --now firewalld

# Crear chain nftables persistente para crowdsec
sudo firewall-cmd --permanent --new-ipset=crowdsec-blacklists --type=hash:ip || true

sudo firewall-cmd --permanent \
  --add-rich-rule='rule source ipset="crowdsec-blacklists" drop' || true

sudo firewall-cmd --reload

# ============================================================
# DESCARGAR ACQUIS SI NO EXISTE
# ============================================================

if [[ ! -f /etc/crowdsec/acquis.yaml ]]; then
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
fi

# ============================================================
# PODMAN CONTAINER
# ============================================================

# CORRECCIÓN AQUÍ: Se añade 'sudo' para verificar el contenedor rootful
if sudo podman container exists crowdsec; then
    echo "[OK] Contenedor crowdsec rootful ya existe."
else
    echo "[INFO] Creando contenedor CrowdSec..."

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
fi

# ============================================================
# ESPERAR ARRANQUE
# ============================================================

echo "[INFO] Esperando inicialización..."

sleep 10

# ============================================================
# INSTALAR BOUNCER NFTABLES
# ============================================================

echo "[INFO] Instalando Firewall Bouncer..."

sudo podman exec crowdsec cscli bouncers add firewall-bouncer -o raw > /tmp/crowdsec-bouncer.key

sudo tee /etc/crowdsec/bouncer.yaml >/dev/null <<EOF
mode: nftables
api_url: http://127.0.0.1:8080/
api_key: $(cat /tmp/crowdsec-bouncer.key)
nftables:
  ipv4:
    enabled: true
    set-only: false
  ipv6:
    enabled: true
    set-only: false
EOF

rm -f /tmp/crowdsec-bouncer.key

# ============================================================
# SERVICIO SYSTEMD DEL BOUNCER
# ============================================================

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
# ACTIVAR COLECCIONES BÁSICAS
# ============================================================

echo "[INFO] Instalando colecciones recomendadas..."

sudo podman exec crowdsec cscli collections install crowdsecurity/linux
sudo podman exec crowdsec cscli collections install crowdsecurity/sshd

# ============================================================
# VALIDACIÓN
# ============================================================

echo
echo "============================================================"
echo " CrowdSec instalado correctamente"
echo "============================================================"
echo

sudo podman exec crowdsec cscli metrics

echo
echo "[OK] CrowdSec funcionando en contenedor."
echo
echo "Logs:"
echo "  sudo podman logs -f crowdsec"
echo
echo "Estado:"
echo "  sudo podman exec crowdsec cscli status"
echo
echo "Decisiones:"
echo "  sudo podman exec crowdsec cscli decisions list"
