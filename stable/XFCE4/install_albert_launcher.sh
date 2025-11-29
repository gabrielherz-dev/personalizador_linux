#!/usr/bin/env bash
set -euo pipefail

# Este script instala Albert en Debian 12 (bookworm)
# Debe ejecutarse como root

REPO_URL="https://download.opensuse.org/repositories/home:/manuelschneid3r/Debian_12"
LIST_FILE="/etc/apt/sources.list.d/home:manuelschneid3r.list"
KEYRING="/usr/share/keyrings/home_manuelschneid3r-archive-keyring.gpg"

echo "[*] Instalando dependencias..."
apt-get update -y
apt-get install -y curl gnupg ca-certificates

echo "[*] Limpiando restos de instalaciones anteriores (si existen)..."
rm -f /etc/apt/trusted.gpg.d/home_manuelschneid3r.gpg || true
rm -f "$LIST_FILE" || true

echo "[*] Importando clave del repositorio..."
curl -fsSL "${REPO_URL}/Release.key" \
  | gpg --dearmor \
  | tee "$KEYRING" >/dev/null
chmod 0644 "$KEYRING"

echo "[*] Añadiendo el repositorio de Albert para Debian 12..."
echo "deb [signed-by=${KEYRING}] ${REPO_URL}/ /" | tee "$LIST_FILE" >/dev/null

echo "[*] Actualizando índices..."
apt-get update

echo "[*] Instalando Albert..."
apt-get install -y albert

echo "✅ ¡Listo! Albert instalado."
echo "Si APT vuelve a quejarse de NO_PUBKEY, comprueba la huella con:"
echo "  gpg --show-keys ${KEYRING}"

