#!/bin/bash

# Este script instala XFCE básico, Cortile, herramientas esenciales y el tema Sweet Dark en Debian 12.

# Salir si ocurre un error
set -e

# Actualizar el sistema
echo "Actualizando el sistema..."
apt update
apt upgrade -y

# 1. Instalación de XFCE Base
echo "Instalando XFCE básico..."
apt install -y xfce4 xfce4-goodies
apt autoremove -y

# 2. Instalación de Herramientas Esenciales de Configuración
echo "Instalando herramientas de configuración básicas..."
apt install -y pavucontrol xfce4-power-manager xfce4-pulseaudio-plugin xfce4-settings

#Instalación para el atajo de teclados para navegar entre espacios de trabajo
apt install -y xdotool

#Instalación de tema oscuro
apt install -y arc-theme

#Instalación de gesator de conexiones y con el plugin de gnome para xfce4
apt install -y network-manager network-manager-gnome
systemctl restart NetworkManager

#Gestióon de bluetooth
apt install -y bluetooth bluez blueman

# Activación del servicio de bluetooth
systemctl start bluetooth
# Y para que se inicie en cada arranque
systemctl enable bluetooth

