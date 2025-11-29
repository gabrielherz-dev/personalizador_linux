#!/bin/bash

# Asegurarse de que xdotool esté instalado
if ! command -v xdotool &>/dev/null; then
    echo "Instala xdotool primero: sudo apt install xdotool"
    exit 1
fi

# Borrar todos los atajos personalizados de xfwm4
#for key in $(xfconf-query -c xfce4-keyboard-shortcuts -l | grep '^/xfwm4/custom/'); do
#    xfconf-query -c xfce4-keyboard-shortcuts -p "$key" -r
#done

# Crear atajos para cambiar de workspace (Super+1..9)
for i in {1..9}; do
    idx=$((i-1))
    xfconf-query -c xfce4-keyboard-shortcuts \
      -p "/commands/custom/<Super>$i" \
      --create -t string -s "xdotool set_desktop $idx"
done

# Crear atajos para mover ventana al workspace (Super+Shift+1..9)
for i in {1..9}; do
    idx=$((i-1))
    xfconf-query -c xfce4-keyboard-shortcuts \
      -p "/commands/custom/<Super><Control>$i" \
      --create -t string -s "xdotool getactivewindow set_desktop_for_window $idx"
done

echo "Atajos configurados:"
echo "- Super+1..9: cambiar de workspace"
echo "- Super+Shift+1..9: mover ventana al workspace"

#terminal
xfconf-query --channel xfce4-keyboard-shortcuts --create --property "/commands/custom/<Super>Return" --type string --set "wezterm"

#screenshots
xfconf-query --channel xfce4-keyboard-shortcuts --create --property "/commands/custom/Print" --type string --set "flatpak run org.flameshot.Flameshot gui"

#Buscador inteligente Albert buscador inteligente
xfconf-query --channel xfce4-keyboard-shortcuts --create --property "/commands/custom/<Super>d" --type string --set ""albert

#Zoom
#xfconf-query --channel xfwm4 --property /general/zoom_in_key --type string --set '<Super>plus'
#xfconf-query --channel xfwm4 --property /general/zoom_out_key --type string --set '<Super>minus'


echo "Recarga XFWM4 con: xfwm4 --replace &"

