#!/bin/bash

# Directorio destino
SCRIPT_DIR="$HOME/.local/bin"

# Crear el directorio si no existe
mkdir -p "$SCRIPT_DIR"

# Script zoom-in
cat <<'EOF' >"$SCRIPT_DIR/zoom-in.sh"
#!/bin/bash
export LC_NUMERIC=C
current=$(gsettings get org.gnome.desktop.a11y.magnifier mag-factor)
current=$(printf "%.1f" "$current")
new=$(echo "$current + 0.1" | bc)
if (( $(echo "$new > 3.0" | bc -l) )); then
    new=3.0
fi
gsettings set org.gnome.desktop.a11y.magnifier mag-factor "$new"
EOF

# Script zoom-out
cat <<'EOF' >"$SCRIPT_DIR/zoom-out.sh"
#!/bin/bash
export LC_NUMERIC=C
current=$(gsettings get org.gnome.desktop.a11y.magnifier mag-factor)
current=$(printf "%.1f" "$current")
new=$(echo "$current - 0.1" | bc)
if (( $(echo "$new < 1.0" | bc -l) )); then
    new=1.0
fi
gsettings set org.gnome.desktop.a11y.magnifier mag-factor "$new"
EOF

# Asignar Super+Z y Super+X
#add_keybinding "zoom-in" "$SCRIPT_DIR/zoom-in.sh" "<Super>z"
#add_keybinding "zoom-out" "$SCRIPT_DIR/zoom-out.sh" "<Super>x"

# Hacer ejecutables
chmod +x "$SCRIPT_DIR/zoom-in.sh" "$SCRIPT_DIR/zoom-out.sh"

echo "✅ Scripts guardados en $SCRIPT_DIR:"
echo "  - zoom-in.sh"
echo "  - zoom-out.sh"
echo ""
echo "👉 Asigna los atajos de teclado en GNOME:"
echo "   - Super+Z → zoom-in.sh"
echo "   - Super+X → zoom-out.sh"

# Asignar las teclas para zoom in y zoom out, <Super>+z y <Super>+x
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
  "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/zoom-in/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/zoom-out/']"

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/zoom-in/ name 'Zoom In'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/zoom-in/ command "$HOME/.local/bin/zoom-in.sh"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/zoom-in/ binding '<Super>z'

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/zoom-out/ name 'Zoom Out'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/zoom-out/ command "$HOME/.local/bin/zoom-out.sh"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/zoom-out/ binding '<Super>x'
