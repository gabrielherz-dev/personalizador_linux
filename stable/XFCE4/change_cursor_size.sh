#!/bin/bash
# Cambiar tema y tamaño del cursor en XFCE4

# Tema del cursor (puedes cambiarlo si tienes otro instalado, como "Adwaita" o "Breeze")
CURSOR_THEME="Adwaita"
# Tamaño del cursor en píxeles
CURSOR_SIZE="48"

echo "Configurando cursor en XFCE4..."

# Configuración para XFCE (a nivel de usuario)
xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "$CURSOR_THEME"
xfconf-query -c xsettings -p /Gtk/CursorThemeSize -s "$CURSOR_SIZE"

# Configuración para Xorg (persistencia en ~/.Xresources)
XR_FILE="$HOME/.Xresources"
grep -q "Xcursor.size" "$XR_FILE" 2>/dev/null && \
    sed -i "s/^Xcursor.size.*/Xcursor.size: $CURSOR_SIZE/" "$XR_FILE" || \
    echo "Xcursor.size: $CURSOR_SIZE" >> "$XR_FILE"

grep -q "Xcursor.theme" "$XR_FILE" 2>/dev/null && \
    sed -i "s/^Xcursor.theme.*/Xcursor.theme: $CURSOR_THEME/" "$XR_FILE" || \
    echo "Xcursor.theme: $CURSOR_THEME" >> "$XR_FILE"

# Recargar configuración de Xresources
xrdb -merge "$XR_FILE"

# Aplicar en la sesión actual (sin reiniciar)
gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null
gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE" 2>/dev/null

echo "Cursor configurado a tema '$CURSOR_THEME' con tamaño $CURSOR_SIZE."
echo "Cierra y abre sesión para aplicar completamente."

