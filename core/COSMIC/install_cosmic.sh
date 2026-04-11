#!/bin/bash
set -e

echo "=== Añadiendo repositorios de System76 (Pop!_OS Noble) a Ubuntu 24.04 ==="
sudo apt-get update
sudo apt-get install -y wget gnupg software-properties-common

# Descargar e instalar la clave GPG de Pop!_OS
wget -qO - https://apt.pop-os.org/proprietary/apt-pop-os.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/pop-os-release.gpg

# Añadir el repositorio de Pop!_OS para la versión noble (24.04)
echo "deb http://apt.pop-os.org/release noble main" | sudo tee /etc/apt/sources.list.d/system76-cosmic.list

echo "=== Actualizando repositorios ==="
sudo apt-get update

echo "=== Instalando Cosmic Desktop (Wayland) y paquetes base ==="
# Instalamos la sesión, el greeter, la terminal y los applets nativos
sudo apt-get install -y cosmic-session cosmic-greeter cosmic-terminal cosmic-applets

echo "=== Configurando Cosmic Greeter como gestor de arranque predeterminado ==="
# Deshabilitamos GDM (si existe) y habilitamos cosmic-greeter
if systemctl is-active --quiet gdm.service; then
    sudo systemctl disable gdm.service
fi
sudo systemctl enable cosmic-greeter.service

echo "=== Instalación base completada ==="
echo "Nota: Cosmic Desktop es EXCLUSIVO de Wayland, por lo que este requisito ya está cubierto por diseño."
