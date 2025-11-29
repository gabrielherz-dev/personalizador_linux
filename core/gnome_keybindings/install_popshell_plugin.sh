# !/bin/bash
# Instalación del GNOME Plugin pop-shell
# NOTA: INSTALAR DESDE XORG Y NO WAYLLAND
git clone https://github.com/pop-os/shell.git
cd shell
git checkout master_jammy
make local-install
# Activar plugin pop-shell
gnome-extensions enable pop-shell@system76.com
# Activar mosaico (Window tilling)
gsettings set org.gnome.shell.extensions.pop-shell tile true
