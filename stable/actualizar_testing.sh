#!/bin/bash

set -e

# 1. Comprobación preliminar
echo ">> Comprobando que eres root..."
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta como root"
  exit 1
fi

echo ">> Haciendo copia de seguridad de tus fuentes de APT..."
cp /etc/apt/sources.list /etc/apt/sources.list.bak.$(date +%F-%T)

# 2. Reemplazar 'bookworm' o 'stable' por 'testing'
echo ">> Actualizando /etc/apt/sources.list a Debian Testing..."
sed -i 's/bookworm/testing/g; s/stable/testing/g' /etc/apt/sources.list

# 3. Opcional: agregar repositorios contrib y non-free si no están
grep -q "contrib" /etc/apt/sources.list || sed -i 's/main/main contrib non-free non-free-firmware/g' /etc/apt/sources.list

# 4. Actualizar índices y paquetes
echo ">> Actualizando índices APT..."
apt update

echo ">> Realizando actualización mínima (apt upgrade)..."
apt upgrade -y

echo ">> Realizando dist-upgrade completo..."
apt full-upgrade -y

# 5. Reinstalar kernel si es necesario
echo ">> Asegurando que el kernel esté actualizado..."
apt install -y linux-image-amd64

# 6. Limpieza de paquetes obsoletos
echo ">> Limpiando el sistema..."
apt autoremove -y
apt autoclean

# 7. Recomendar reinicio
echo ">> Actualización completada. Reinicia el sistema para aplicar todos los cambios."
