#!/bin/bash
# Script para reconstruir el panel XFCE4 con iconos oficiales (o del sistema si está instalada la app)

# ====== CONFIGURACIÓN ======
PANEL_ID=1
PANEL_DIR="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
PANEL_FILE="$PANEL_DIR/xfce4-panel.xml"
LAUNCHERS_DIR="$HOME/.config/xfce4/panel"

# Lista de aplicaciones y sus iconos oficiales
declare -A apps=(
  ["obsidian"]="https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/icons/icon.png"
  ["zen-browser"]="https://raw.githubusercontent.com/zen-browser/brand/main/logo.png"
  ["albert"]="https://albertlauncher.github.io/images/logo.png"
  ["wezterm"]="https://wezfurlong.org/wezterm/images/icon.png"
  ["firefox"]="https://raw.githubusercontent.com/mozilla/bedrock/main/media/img/firefox/logo.png"
  ["brave"]="https://brave.com/static-assets/images/brave-logo-sans-text.svg"
  ["keepassxc"]="https://keepassxc.org/images/keepassxc-icon.svg"
  ["chromium"]="https://upload.wikimedia.org/wikipedia/commons/c/ca/Chromium_icon.svg"
  ["vlc"]="https://upload.wikimedia.org/wikipedia/commons/3/3f/VLC_Icon.svg"
  ["arandr"]="https://gitlab.com/arandr/arandr/-/raw/master/data/icons/48x48/arandr.png"
  ["spotify"]="https://upload.wikimedia.org/wikipedia/commons/8/84/Spotify_icon.svg"
  ["okular"]="https://apps.kde.org/assets/icons/okular.svg"
  ["gimp"]="https://upload.wikimedia.org/wikipedia/commons/4/45/The_GIMP_icon_-_gnome.svg"
)

# ====== FUNCIONES ======
descargar_iconos() {
  local app=$1
  local url=$2
  local dir="$HOME/.local/share/icons/custom/$app"
  mkdir -p "$dir"

  echo "[INFO] Descargando iconos para $app"
  wget -qO "$dir/icon.png" "$url" || echo "[WARN] No se pudo descargar $app"

  # Crear versiones 32x32 y 64x64
  if command -v convert &>/dev/null; then
    convert "$dir/icon.png" -resize 32x32 "$dir/icon-32.png"
    convert "$dir/icon.png" -resize 64x64 "$dir/icon-64.png"
  fi
}

crear_lanzador() {
  local app=$1
  local dir="$LAUNCHERS_DIR/$app"
  mkdir -p "$dir"

  local desktop_file="$dir/$app.desktop"

  # Usar icono del sistema si existe
  if command -v "flatpak" &>/dev/null && flatpak info --show-name "$app" &>/dev/null; then
    icono="$app"
  elif command -v "$app" &>/dev/null; then
    icono="$app"
  else
    icono="$HOME/.local/share/icons/custom/$app/icon.png"
  fi

  cat > "$desktop_file" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$app
Exec=$app
Icon=$icono
Terminal=false
EOF
}

# ====== INICIO ======
echo "[INFO] Limpiando configuración anterior..."
rm -f "$PANEL_FILE"
rm -rf "$LAUNCHERS_DIR"/*

echo "[INFO] Descargando iconos..."
for app in "${!apps[@]}"; do
  descargar_iconos "$app" "${apps[$app]}"
done

echo "[INFO] Creando lanzadores..."
for app in "${!apps[@]}"; do
  crear_lanzador "$app"
done

echo "[INFO] Configurando nuevo panel..."
mkdir -p "$PANEL_DIR"
cat > "$PANEL_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-panel" version="1.0">
  <property name="panels" type="array">
    <value type="int" value="$PANEL_ID"/>
  </property>
  <property name="panels/$PANEL_ID" type="empty">
    <property name="plugin-ids" type="array">
EOF

ID=1
for app in "${!apps[@]}"; do
  echo "      <value type=\"int\" value=\"$ID\"/>" >> "$PANEL_FILE"
  ((ID++))
done

cat >> "$PANEL_FILE" <<EOF
    </property>
  </property>
</channel>
EOF

echo "[INFO] Panel reconstruido. Reiniciando xfce4-panel..."
xfce4-panel --restart

echo "[OK] Configuración completada."

