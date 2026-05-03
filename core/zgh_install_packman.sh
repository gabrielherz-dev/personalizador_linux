
#!/bin/bash
# Script para configurar Packman y códecs en openSUSE Leap

echo "--- Configurando Repositorio Packman Essentials ---"
# Añadir el repositorio con prioridad alta (90) para que zypper lo prefiera
sudo zypper ar -cfp 90 "https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Leap_\$releasever/Essentials/" packman-essentials

echo "--- Refrescando repositorios ---"
sudo zypper ref

echo "--- Realizando cambio de proveedor para códecs (Vendor Change) ---"
# Este paso es CRUCIAL: cambia los paquetes de video de openSUSE a Packman
sudo zypper dup --from packman-essentials --allow-vendor-change

echo "--- Instalando códecs adicionales y FFmpeg ---"
#sudo zypper install --allow-vendor-change ffmpeg-7 libavcodec-full vlc-#codecs gstreamer-plugins-libav gstreamer-plugins-bad gstreamer-plugins-ugly #gstreamer-plugins-good-extra
sudo zypper install -t pattern multimedia
echo "--- Proceso completado ---"

