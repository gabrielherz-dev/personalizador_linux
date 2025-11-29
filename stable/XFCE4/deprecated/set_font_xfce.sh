#!/bin/bash

# Define el nombre de la fuente y el tamaño deseado
FUENTE_NOMBRE="Sans"
FUENTE_TAMANO="16"

# Cambia la fuente predeterminada
xfconf-query -c xsettings -p /Gtk/FontName -s "${FUENTE_NOMBRE} ${FUENTE_TAMANO}"

# Cambia la fuente del título de la ventana
xfconf-query -c xfwm4 -p /general/title_font -s "Sans Bold ${FUENTE_TAMANO}"

# Puedes añadir más configuraciones aquí si lo necesitas
echo "Fuentes cambiadas a ${FUENTE_NOMBRE} con tamaño ${FUENTE_TAMANO}."
