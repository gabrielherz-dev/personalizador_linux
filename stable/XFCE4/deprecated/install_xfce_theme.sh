#!/bin/bash
set -e

# ==== CONFIGURACIÓN ====
THEME_NAME="Sweet-Dark"
THEME_REPO="https://github.com/EliverLara/Sweet.git"
THEME_TMP="/tmp/Sweet"
THEME_DIR="/usr/share/themes"

# ==== FUNCIONES ====
function detect_panel() {
    echo "[+] Detectando panel XFCE..."
    PANEL_ID=$(xfconf-query -c xfce4-panel -l | grep -o '/panels/panel-[0-9]\+' | head -n 1)

    if [ -z "$PANEL_ID" ]; then
        echo "[!] No se detectó ningún panel XFCE. Abortando."
        exit 1
    fi

    echo "[+] Panel detectado: $PANEL_ID"
}

function apply_theme() {
    echo "[+] Aplicando tema en XFCE..."

    xfconf-query -c xsettings -p /Net/ThemeName -s "$THEME_NAME" || true
    xfconf-query -c xfwm4 -p /general/theme -s "$THEME_NAME" || true

    # Detectar si existe background-mode
    if xfconf-query -c xfce4-panel -p "$PANEL_ID/background-mode" >/dev/null 2>&1; then
        xfconf-query -c xfce4-panel -p "$PANEL_ID/background-mode" -s 0
    fi

    # Borrar imagen de fondo si existe background-image
    if xfconf-query -c xfce4-panel -p "$PANEL_ID/background-image" >/dev/null 2>&1; then
        xfconf-query -c xfce4-panel -p "$PANEL_ID/background-image" -s ""
    fi
}

# ==== EJECUCIÓN ====
# Verificar que estamos en sesión gráfica
if [ -z "$DISPLAY" ] || [ -z "$XAUTHORITY" ]; then
    echo "[!] No estás en una sesión gráfica de XFCE. Abre XFCE y ejecuta este script desde ahí."
    exit 1
fi

# Instalar dependencias necesarias
detect_panel
apply_theme

echo "[✓] Tema $THEME_NAME instalado y configurado con éxito."

