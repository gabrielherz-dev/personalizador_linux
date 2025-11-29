#!/bin/bash

# Comprobar si se ha proporcionado un tamaño de fuente
if [ -z "$1" ]; then
    echo "Uso: $0 <tamaño_de_fuente>"
    echo "Ejemplo: $0 12"
    exit 1
fi

NEW_FONT_SIZE=$1

# Comprobar si el valor es un número
if ! [[ "$NEW_FONT_SIZE" =~ ^[0-9]+$ ]]; then
    echo "Error: El tamaño de la fuente debe ser un número entero."
    exit 1
fi

# Configurar el tamaño de la fuente para el sistema
xfconf-query -c xsettings -p /Gtk/FontName -s "Sans $NEW_FONT_SIZE"

# Opcional: Afectar al terminal de Xfce (xfce4-terminal) si lo usas
# xfconf-query -c xfce4-terminal -p /font-name -s "Monospace $NEW_FONT_SIZE"

echo "El tamaño de la fuente se ha cambiado a $NEW_FONT_SIZE. Es posible que tengas que reiniciar la sesión o el panel para ver todos los cambios."
