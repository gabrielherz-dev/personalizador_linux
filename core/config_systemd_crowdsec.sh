#!/usr/bin/env bash

set -Eeuo pipefail

readonly CROWDSEC_SERVICE="crowdsec.service"
readonly BOUNCER_SERVICE="crowdsec-firewall-bouncer.service"

readonly CROWDSEC_SERVICE_PATH="/etc/systemd/system/${CROWDSEC_SERVICE}"
readonly BOUNCER_SERVICE_PATH="/etc/systemd/system/${BOUNCER_SERVICE}"

echo "[INFO] =================================================="
echo "[INFO] Configurando servicios systemd de CrowdSec"
echo "[INFO] =================================================="

# ============================================================
# SERVICIO CROWDSEC
# ============================================================

echo "[INFO] Creando servicio systemd para CrowdSec..."

sudo tee "${CROWDSEC_SERVICE_PATH}" >/dev/null <<'EOF'
[Unit]
Description=CrowdSec Container
Wants=network-online.target
After=network-online.target firewalld.service

[Service]
Type=simple

Restart=always
RestartSec=10

ExecStart=/usr/bin/podman start -a crowdsec
ExecStop=/usr/bin/podman stop -t 10 crowdsec

[Install]
WantedBy=multi-user.target
EOF

# ============================================================
# SERVICIO BOUNCER
# ============================================================

echo "[INFO] Creando servicio systemd para Firewall Bouncer..."

sudo tee "${BOUNCER_SERVICE_PATH}" >/dev/null <<'EOF'
[Unit]
Description=CrowdSec Firewall Bouncer Container

Requires=crowdsec.service
After=crowdsec.service network-online.target firewalld.service

[Service]
Type=simple

Restart=always
RestartSec=10

ExecStartPre=/usr/bin/sleep 5

ExecStart=/usr/bin/podman start -a crowdsec-firewall-bouncer
ExecStop=/usr/bin/podman stop -t 10 crowdsec-firewall-bouncer

[Install]
WantedBy=multi-user.target
EOF

# ============================================================
# SYSTEMD
# ============================================================

echo "[INFO] Recargando systemd..."

sudo systemctl daemon-reload

# ============================================================
# ENABLE
# ============================================================

echo "[INFO] Activando CrowdSec al arranque..."

sudo systemctl enable "${CROWDSEC_SERVICE}"

echo "[INFO] Activando Firewall Bouncer al arranque..."

sudo systemctl enable "${BOUNCER_SERVICE}"

# ============================================================
# START
# ============================================================

echo "[INFO] Iniciando CrowdSec..."

sudo systemctl start "${CROWDSEC_SERVICE}"

echo "[INFO] Esperando estabilización..."

sleep 10

echo "[INFO] Iniciando Firewall Bouncer..."

sudo systemctl start "${BOUNCER_SERVICE}"

# ============================================================
# VALIDACIÓN
# ============================================================

echo
echo "=================================================="
echo " Servicios systemd configurados correctamente"
echo "=================================================="
echo

echo "[INFO] Estado CrowdSec:"
systemctl status "${CROWDSEC_SERVICE}" --no-pager

echo
echo "[INFO] Estado Firewall Bouncer:"
systemctl status "${BOUNCER_SERVICE}" --no-pager

echo
echo "[INFO] Contenedores activos:"
sudo podman ps -f name=crowdsec
