#!/bin/bash
# Script para configurar Packman y códecs en openSUSE Leap 16.0

echo "--- Eliminando repositorio previo (si existe) ---"
sudo zypper rr packman-essentials

echo "--- Configurando Repositorio Packman Essentials para Leap 16.0 ---"
# Usamos la URL directa que está confirmada como operativa para Leap 16
sudo zypper ar -cfgp 90 "http://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Leap_16.0/Essentials/" packman-essentials

echo "--- Refrescando repositorios e importando claves ---"
sudo zypper --gpg-auto-import-keys ref

echo "--- Realizando cambio de proveedor para códecs (Vendor Change) ---"
sudo zypper dup --from packman-essentials --allow-vendor-change

echo "--- Instalando el patrón multimedia ---"
sudo zypper install -t pattern multimedia

echo "--- Proceso completado ---"
