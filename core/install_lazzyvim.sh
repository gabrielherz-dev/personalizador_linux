# !/bin/bash
# Instalación de lazzyvim
readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RUTA_ACTUAL/../config/constantes.sh"

if [[ ! -d "$TARGET_HOME/.config/nvim" ]]; then
  mkdir -p "$TARGET_HOME/.config/nvim"
else
  rm -r "$TARGET_HOME/.config/nvim"
  mkdir -p "$TARGET_HOME/.config/nvim"
fi
git clone https://github.com/LazyVim/starter "$TARGET_HOME/.config/nvim"

# Cambiando los permisos del directorio descargado
chown -R gherz:gherz "$TARGET_HOME/.config/nvim"
find "$TARGET_HOME/.config/nvim" -type d -exec chmod 755 {} +
find "$TARGET_HOME/.config/nvim" -type f -exec chmod 644 {} +
