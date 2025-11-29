#!/bin/bash

# Uso: ./asignar_tecla.sh "<Super>t" "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/" "binding"

COMBINACION="$1"
ESQUEMA="$2"
CLAVE="$3"

if [ -z "$COMBINACION" ] || [ -z "$ESQUEMA" ] || [ -z "$CLAVE" ]; then
  echo "Uso: $0 '<combinación>' '<esquema>' '<clave>'"
  exit 1
fi

# Buscar si la combinación ya está asignada
LINEA_EXISTENTE=$(gsettings list-recursively | grep "$COMBINACION")

if [ -n "$LINEA_EXISTENTE" ]; then
  # Extraer esquema y clave
  ESQUEMA_EXISTE=$(echo "$LINEA_EXISTENTE" | awk '{print $1}')
  CLAVE_EXISTE=$(echo "$LINEA_EXISTENTE" | awk '{print $2}')

  echo "Desasignando '$COMBINACION' de $ESQUEMA_EXISTE $CLAVE_EXISTE"
  gsettings set "$ESQUEMA_EXISTE" "$CLAVE_EXISTE" "['']"
fi

# Asignar la nueva combinación
echo "Asignando '$COMBINACION' a $ESQUEMA $CLAVE"
gsettings set "$ESQUEMA" "$CLAVE" "['$COMBINACION']"
