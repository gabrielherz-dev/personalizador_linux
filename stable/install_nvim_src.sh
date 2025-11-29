# !/bin/bash
#  Instalación de Neo vim desde el repositorio en github
apt update
apt upgrade
apt remove neovim
apt install -y ninja-build gettext cmake unzip curl git build-essential \
  libtool libtool-bin autoconf automake pkg-config \
  libluajit-5.1-dev libunibilium-dev libutf8proc-dev \
  libmsgpack-dev libtermkey-dev libvterm-dev
# Se limpia por si ha habido una compilación anterior
make distclean
#make distclean Instalando neovim
git clone https://github.com/neovim/neovim.git
cd neovim
# Se utiliza la rama estable para mayor seguridad
git checkout stable
# se compila y se crea el directorio ./build con el binario
make CMAKE_BUILD_TYPE=Release
# Se instala nvim en /usr/local/bin/nvim
make install
# Se imprime la versión para comprobar que se ha instalado
