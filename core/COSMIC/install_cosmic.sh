#!/bin/bash
set -e

echo "=== Añadiendo PPA de Cosmic Epoch para Ubuntu 24.04 ==="
sudo apt-get update
sudo apt-get install -y software-properties-common

# Añadimos el repositorio PPA oficial de la comunidad para Cosmic en Ubuntu 24.04
sudo add-apt-repository -y ppa:hepp3n/cosmic-epoch

echo "=== Actualizando repositorios ==="
sudo apt-get update

echo "=== Instalando Cosmic Desktop (Wayland) y paquetes base ==="
# Instalamos la sesión, el greeter, la terminal y los applets
sudo apt-get install -y cosmic-session cosmic-greeter cosmic-terminal cosmic-applets

echo "=== Configurando Cosmic Greeter como gestor de arranque predeterminado ==="
# Deshabilitamos GDM (si existe y está activo) y habilitamos cosmic-greeter
if systemctl is-active --quiet gdm.service; then
    sudo systemctl disable gdm.service
fi
sudo systemctl enable cosmic-greeter.service

echo "=== Instalación base completada ==="
echo "Nota: Durante la instalación, si te pide elegir el gestor de sesiones por defecto (Default display manager), selecciona 'cosmic-greeter'."
