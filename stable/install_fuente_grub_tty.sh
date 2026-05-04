#!/bin/bash

set -e

# Verificar si se ejecuta como root
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script debe ejecutarse como root." >&2
  exit 1
fi

# Configuraciones
GRUB_CFG="/etc/default/grub"
GRUB_FONT_DIR="/boot/grub/fonts"
GRUB_FONT_FILE="$GRUB_FONT_DIR/terminus32.pf2"
FONT_SOURCE="/usr/share/consolefonts/Uni2-TerminusBold32x16.psf.gz"

# Verificar que la fuente exista
if [ ! -f "$FONT_SOURCE" ]; then
  echo "❌ No se encuentra la fuente: $FONT_SOURCE"
  echo "Instala el paquete 'fonts-terminus' o verifica la ruta."
  exit 1
fi

# Generar la fuente .pf2 si no existe
if [ ! -f "$GRUB_FONT_FILE" ]; then
  echo "🛠️  Generando fuente GRUB terminus32.pf2 desde $FONT_SOURCE..."
  mkdir -p "$GRUB_FONT_DIR"
  grub-mkfont -s 32 -o "$GRUB_FONT_FILE" "$FONT_SOURCE"
fi

# Función para agregar o reemplazar parámetros en /etc/default/grub
set_grub_param() {
  local key="$1"
  local value="$2"
  if grep -q "^$key=" "$GRUB_CFG"; then
    sed -i "s|^$key=.*|$key=\"$value\"|" "$GRUB_CFG"
  else
    echo "$key=\"$value\"" >>"$GRUB_CFG"
  fi
}

echo "📝 Configurando /etc/default/grub..."
set_grub_param "GRUB_FONT" "$GRUB_FONT_FILE"
set_grub_param "GRUB_GFXMODE" "1024x768"
set_grub_param "GRUB_GFXPAYLOAD_LINUX" "keep"

echo "🔄 Actualizando GRUB..."
update-grub

echo "✅ Fuente de GRUB actualizada con Uni2-TerminusBold32x16 y configuración de resolución aplicada."
