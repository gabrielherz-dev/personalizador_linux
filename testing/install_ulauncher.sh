
#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Instalación de Ulauncher Debian 13 con autostart global
# -----------------------------

# Dependencias
su -c "apt install -y python3-gi gir1.2-gtk-3.0 libgirepository1.0-dev wget"

# Descargar la versión estable
wget https://github.com/Ulauncher/Ulauncher/releases/download/5.15.7/ulauncher_5.15.7_all.deb -O ulauncher_5.15.7_all.deb

# Instalar el paquete (resuelve dependencias automáticamente)
su -c "apt install -y ./ulauncher_5.15.7_all.deb"

# Crear el archivo .desktop para autostart en todos los usuarios
AUTOSTART_FILE="/etc/xdg/autostart/ulauncher.desktop"

su -c "mkdir -p /etc/xdg/autostart"

su -c "cat > $AUTOSTART_FILE <<'EOF'
[Desktop Entry]
Type=Application
Name=Ulauncher
Exec=ulauncher --hide-window
X-GNOME-Autostart-enabled=true
NoDisplay=false
Hidden=false
Comment=Launcher for Linux
EOF"

echo "✅ Instalación completada. Ulauncher se iniciará automáticamente para todos los usuarios."
