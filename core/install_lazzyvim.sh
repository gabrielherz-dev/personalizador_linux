#!/bin/bash
# ==========================
# Instalación de LazyVim
# ==========================

readonly RUTA_ACTUAL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RUTA_ACTUAL/../config/constantes.sh"

echo "Preparando instalación de LazyVim..."

# 1. Limpieza de configuraciones y cachés anteriores (Requisito de LazyVim)
rm -rf "$TARGET_HOME/.config/nvim"
rm -rf "$TARGET_HOME/.local/share/nvim"
rm -rf "$TARGET_HOME/.local/state/nvim"
rm -rf "$TARGET_HOME/.cache/nvim"

# 2. Clonar el repositorio base de LazyVim (git creará la carpeta .config/nvim)
git clone https://github.com/LazyVim/starter "$TARGET_HOME/.config/nvim"

# 3. Eliminar la carpeta .git del starter para que puedas crear tu propio historial
rm -rf "$TARGET_HOME/.config/nvim/.git"

# 4. Ajustar permisos dinámicamente
# Detecta al dueño de TARGET_HOME para no hardcodear "gherz"
USER_OWNER=$(stat -c '%U' "$TARGET_HOME")
GROUP_OWNER=$(stat -c '%G' "$TARGET_HOME")

# IMPORTANTE: chown solo funciona si el script se ejecuta con sudo
chown -R "$USER_OWNER:$GROUP_OWNER" "$TARGET_HOME/.config/nvim"
find "$TARGET_HOME/.config/nvim" -type d -exec chmod 755 {} +
find "$TARGET_HOME/.config/nvim" -type f -exec chmod 644 {} +

echo "LazyVim se ha instalado correctamente."
