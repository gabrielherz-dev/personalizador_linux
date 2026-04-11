#!/bin/bash

echo "=== Configurando integraciones de GTK y Qt ==="

# 1. Configuración de GSettings (Afecta a apps GTK bajo Wayland)
# Modo oscuro
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
# Cursor tamaño 72 (3x el normal de 24)
gsettings set org.gnome.desktop.interface cursor-size 72
# Fuente a 13.5pt (aprox 18px) Bold
gsettings set org.gnome.desktop.interface font-name 'Ubuntu Bold 13.5'
gsettings set org.gnome.desktop.interface document-font-name 'Ubuntu Bold 13.5'
gsettings set org.gnome.desktop.interface monospace-font-name 'Ubuntu Mono Bold 14'
# Tema de alto contraste (si está disponible en Ubuntu)
gsettings set org.gnome.desktop.interface gtk-theme 'HighContrastInverse'

# 2. Configurar GTK-3.0 y GTK-4.0 manualmente para asegurar compatibilidad
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0

cat <<EOF > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=HighContrastInverse
gtk-font-name=Ubuntu Bold 13.5
gtk-cursor-theme-size=72
EOF

cp ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini

# 3. Preparar entorno para Qt (Forzar a usar el tema de Wayland/GTK)
if ! grep -q "QT_QPA_PLATFORMTHEME" ~/.bashrc; then
    echo "export QT_QPA_PLATFORMTHEME=gtk3" >> ~/.bashrc
    echo "export QT_WAYLAND_DISABLE_WINDOWDECORATION=1" >> ~/.bashrc
fi

echo "=== Configuración aplicada ==="
echo "Para que la interfaz NATIVA de Cosmic tenga la letra en 18px, el fondo oscuro y el cursor gigante, entra a: Ajustes de Cosmic -> Escritorio -> Apariencia (Dark Mode) y Pantalla (Escala/Texto)."
