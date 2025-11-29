#!/bin/bash
set -e

# ==== CONFIGURACIÓN ====
THEME_NAME="Sweet-Dark"
THEME_REPO="https://github.com/EliverLara/Sweet.git"
THEME_TMP="/tmp/Sweet"
THEME_DIR="/usr/share/themes"

# ==== FUNCIONES ====
function install_theme() {
    echo "[+] Instalando tema $THEME_NAME..."

    # Clonar tema
    rm -rf "$THEME_TMP"
    git clone "$THEME_REPO" "$THEME_TMP"

    # Moverlo a /usr/share/themes
    mkdir -p "$THEME_DIR"
    rm -rf "$THEME_DIR/Sweet"
    mv "$THEME_TMP" "$THEME_DIR/"
}
# Instalar dependencias necesarias
echo "[+] Instalando dependencias..."
apt install -y git xfconf

install_theme



echo "[✓] Tema $THEME_NAME descargado con éxito."

