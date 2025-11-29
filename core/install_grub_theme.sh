#!/bin/bash

readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RUTA_ACTUAL/../config/constantes.sh"

# Ruta donde tienes el tema actualmente
TEMA_ORIGEN="$RUTA_ACTUAL/config/DEBIAN/GRUB_Debian"
# Ruta destino
DESTINO="/boot/grub/themes/Debian"
# Archivo del tema (debe existir como 'theme.txt')
ARCHIVO_TEMA="theme.txt"
# Línea que contiene la ubicación del tema
LINEA_TEMA="GRUB_THEME=$DESTINO/GRUB_Debian/$ARCHIVO_TEMA"

echo "Te,a seleccionado $1"
if [[ "$1" == "$DEBIAN_THEME" ]]; then
  TEMA_ORIGEN="$RUTA_ACTUAL/config/DEBIAN/GRUB_Debian"
  # Ruta destino
  DESTINO="/boot/grub/themes/Debian"
  # Línea que contiene la ubicación del tema
  LINEA_TEMA="GRUB_THEME=$DESTINO/GRUB_Debian/$ARCHIVO_TEMA"

fi
if [[ "$1" == "$THINKPAD_THEME" ]]; then
  TEMA_ORIGEN="$RUTA_ACTUAL/config/THINKPAD/GRUB-Debian-thinkpad"
  # Ruta destino
  DESTINO="/boot/grub/themes/Thinkpad"
  # Línea que contiene la ubicación del tema
  LINEA_TEMA="GRUB_THEME=$DESTINO/GRUB-Debian-thinkpad/$ARCHIVO_TEMA"
fi

# Verifica que el archivo del tema exista
if [ ! -f "$TEMA_ORIGEN/$ARCHIVO_TEMA" ]; then
  echo "No se encontró $ARCHIVO_TEMA en $TEMA_ORIGEN. Abortando."
  exit 1
fi

# Instalando wallpapers en el sistema
cp -r "$RUTA_ORIGEN/config/wallpapers" /usr/share/wallpapers

# Crea el directorio de destino
echo "Copiando tema a $DESTINO..."
mkdir -p "$DESTINO"
cp -r "$TEMA_ORIGEN" "$DESTINO"

# Configura el tema en GRUB
GRUB_CFG="/etc/default/grub"
#LINEA_TEMA="GRUB_THEME=$DESTINO/$ARCHIVO_TEMA"

if grep -q "^GRUB_THEME=" "$GRUB_CFG"; then
  echo "Actualizando línea GRUB_THEME existente..."
  sed -i "s|^GRUB_THEME=.*|$LINEA_TEMA|" "$GRUB_CFG"
else
  echo "Añadiendo línea GRUB_THEME..."
  echo "$LINEA_TEMA" | tee -a "$GRUB_CFG"
fi

# Actualiza GRUB
echo "Actualizando GRUB..."
if command -v update-grub &>/dev/null; then
  update-grub
elif command -v grub-mkconfig &>/dev/null; then
  grub-mkconfig -o /boot/grub/grub.cfg
else
  echo "No se encontró ningún comando para actualizar GRUB."
  exit 1
fi

echo "Tema aplicado y GRUB actualizado correctamente."
