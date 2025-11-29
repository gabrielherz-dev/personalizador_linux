#!/bin/bash

# Este script instala Ulauncher en Debian 12 desde el código fuente
# Se asume que el script se ejecuta como root (usando 'su -')

# 1. Actualizar el índice de paquetes y paquetes del sistema
echo "Actualizando el sistema..."
apt update -y
apt upgrade -y

# 2. Instalar dependencias para compilar y ejecutar Ulauncher
echo "Instalando dependencias..."
apt install -y git python3 python3-pip python3-gi python3-dbus python3-gi-cairo gir1.2-gtk-3.0 gir1.2-gdkpixbuf-2.0 gir1.2-glib-2.0

# 3. Clonar el repositorio de Ulauncher desde GitHub
echo "Clonando el repositorio de Ulauncher..."
# Se clona el repositorio en /tmp para una instalación temporal
cd /tmp
git clone https://github.com/Ulauncher/Ulauncher.git

# 4. Instalar Ulauncher
echo "Instalando Ulauncher..."
cd Ulauncher
python3 setup.py install

# 5. Crear el archivo .desktop para el lanzador de aplicaciones
echo "Creando el archivo de lanzador de aplicaciones..."
# Se copia el archivo .desktop al directorio de aplicaciones del sistema
cp data/ulauncher.desktop /usr/share/applications/

# 6. Limpiar el directorio de instalación
echo "Limpiando archivos de instalación..."
cd /tmp
rm -rf Ulauncher

echo "¡Ulauncher se ha instalado correctamente!"
echo "Ahora puedes buscarlo y ejecutarlo desde el menú de aplicaciones."
