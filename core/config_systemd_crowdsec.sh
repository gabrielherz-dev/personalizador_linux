#!/usr/bin/env bash

set -Eeuo pipefail

readonly SERVICE_NAME="crowdsec.service"
readonly SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"

echo "[INFO] =================================================="
echo "[INFO] Configurando servicio systemd para CrowdSec"
echo "[INFO] =================================================="

echo "[INFO] Creando unidad systemd..."

sudo tee "${SERVICE_PATH}" >/dev/null <<'EOF'
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

echo "[INFO] Recargando systemd..."

sudo systemctl daemon-reload

echo "[INFO] Habilitando arranque automático..."

sudo systemctl enable "${SERVICE_NAME}"

echo "[INFO] Iniciando servicio..."

sudo systemctl start "${SERVICE_NAME}"

echo
echo "=================================================="
echo " Servicio CrowdSec configurado correctamente"
echo "=================================================="
echo

echo "[INFO] Estado del servicio:"
systemctl status "${SERVICE_NAME}" --no-pager

echo
echo "[INFO] Contenedor CrowdSec:"
sudo podman ps -f name=crowdsec
