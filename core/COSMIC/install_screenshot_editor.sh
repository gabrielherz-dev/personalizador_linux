#!/bin/bash

# instalación de screenshots y del editor 
sudo apt install grim drawing

# Directorio temporal definido
TMP_DIR="/tmp"

# Generar nombre con el formato img_hora_minutos_segundos
TIMESTAMP=$(date +"%H%M%S")
FILENAME="img_${TIMESTAMP}.png"
FILEPATH="${TMP_DIR}/${FILENAME}"

echo "Capturando pantalla entera..."
# grim captura la pantalla en entornos Wayland de manera silenciosa
if grim "$FILEPATH"; then
    echo "Imagen guardada en $FILEPATH"
    
    # Abrir la imagen en 'drawing' para edición/resaltado rápido
    # Se abrirá la interfaz para que dibujes, recortes o resaltes, y luego guardes.
    drawing "$FILEPATH" &
else
    echo "Error: No se pudo capturar la pantalla. Asegúrate de estar en una sesión Wayland válida."
    exit 1
fi
