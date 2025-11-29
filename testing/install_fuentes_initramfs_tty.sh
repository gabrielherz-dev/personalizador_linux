#!/bin/bash
set -e

FUENTE="Uni2-TerminusBold32x16.psf.gz"
RUTA="/usr/share/consolefonts/$FUENTE"

# Verificar que la fuente existe
if [ ! -f "$RUTA" ]; then
  echo "❌ La fuente $FUENTE no se encuentra en $RUTA."
  echo "¿Tienes instalado el paquete fonts-terminus?"
  exit 1
fi

# Configurar la fuente en initramfs
echo "✅ Configurando $FUENTE como fuente por defecto para initramfs..."
sudo sed -i '/^FONT=/d' /etc/initramfs-tools/initramfs.conf
echo "FONT=$FUENTE" | sudo tee -a /etc/initramfs-tools/initramfs.conf

# Regenerar initramfs
echo "🔄 Regenerando initramfs..."
sudo update-initramfs -u

echo "✅ Fuente configurada correctamente en initramfs: $FUENTE"
