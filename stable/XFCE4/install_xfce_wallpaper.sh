#!/bin/bash

# Este script cambia el fondo de escritorio en XFCE4.
# Se asegura de que el fondo se aplique en todos los monitores y escritorios.

# Verificamos si se proporcionó una ruta de imagen como argumento
if [ -z "$1" ]; then
    echo "Uso: $0 <ruta_a_la_imagen>"
    echo "Ejemplo: $0 /home/usuario/Imágenes/mi_fondo.jpg"
    exit 1
fi

WALLPAPER_PATH="$1"

# Verificamos si el archivo de imagen existe
if [ ! -f "$WALLPAPER_PATH" ]; then
    echo "Error: El archivo no existe en la ruta especificada."
    exit 1
fi

# Obtenemos el nombre de la propiedad del fondo de escritorio
# Esto puede variar si tienes múltiples monitores o configuraciones específicas
PROP_NAME=$(xfconf-query -c xfce4-desktop -l | grep -E 'last-image$' | head -n 1)

# Verificamos si la propiedad del fondo se encontró
if [ -z "$PROP_NAME" ]; then
    echo "Error: No se pudo encontrar la propiedad de configuración del fondo de escritorio."
    exit 1
fi

# Establecemos el fondo de escritorio para todos los escritorios y monitores
for PROP_NAME in $(xfconf-query -c xfce4-desktop -l | grep -E 'image-path$|last-image$'); do
    xfconf-query -c xfce4-desktop -p "$PROP_NAME" -s "$WALLPAPER_PATH"
done

# Opcional: También puedes establecer el modo de visualización de la imagen (ej. 'zoom', 'tiled', 'stretched')
# Aquí se usa 'zoom' como valor por defecto.
# Puedes cambiar 'zoom' por 'stretched', 'scaled', 'tiled', 'centered' o 'zoomed'
for PROP_NAME in $(xfconf-query -c xfce4-desktop -l | grep -E 'image-style$|last-image-style$'); do
    xfconf-query -c xfce4-desktop -p "$PROP_NAME" -s 5 # 5 = zoom
done

echo "El fondo de escritorio se ha cambiado correctamente a: $WALLPAPER_PATH"
