
#!/bin/bash

# Nombre y UUID de la extensión
EXTENSION_NAME="Tiling Assistant"
EXTENSION_UUID="tiling-assistant@fthx"
EXTENSION_ID="3733"

# Funciones útiles
print_status() { echo -e "\n\e[1m\e[34m[INFO]\e[0m $1"; }
print_success() { echo -e "\n\e[1m\e[32m[ÉXITO]\e[0m $1"; }
print_error() { echo -e "\n\e[1m\e[31m[ERROR]\e[0m $1"; exit 1; }

print_status "Instalando $EXTENSION_NAME..."

# Verificar GNOME Shell
if ! command -v gnome-shell &>/dev/null; then
    print_error "GNOME Shell no está instalado."
fi

# Instalar dependencias
print_status "Instalando dependencias..."
sudo apt update
sudo apt install -y curl unzip chrome-gnome-shell gnome-shell-extensions \
    gnome-extensions-app || print_error "Fallo al instalar dependencias."

# Detectar versión de GNOME Shell (solo número mayor)
GNOME_VER=$(gnome-shell --version | grep -oP '[0-9]+' | head -1)
if [ -z "$GNOME_VER" ]; then
    print_error "No se pudo detectar la versión de GNOME Shell."
fi
print_status "Versión de GNOME Shell: $GNOME_VER"

# Directorios y archivos
EXTENSION_DIR="$HOME/.local/share/gnome-shell/extensions/$EXTENSION_UUID"
ZIP_FILE="extension-$EXTENSION_ID-$GNOME_VER.zip"

# Descargar la extensión adecuada
DOWNLOAD_URL="https://extensions.gnome.org/download-extension/$EXTENSION_UUID/$GNOME_VER.zip"
print_status "Descargando $DOWNLOAD_URL"
curl -fL "$DOWNLOAD_URL" -o "$ZIP_FILE" || \
    print_error "Fallo al descargar la extensión. Posiblemente no hay versión para GNOME $GNOME_VER."

# Crear directorio y descomprimir
print_status "Creando directorio: $EXTENSION_DIR"
mkdir -p "$EXTENSION_DIR" || print_error "No se pudo crear el directorio."
print_status "Descomprimiendo extensión..."
unzip -o "$ZIP_FILE" -d "$EXTENSION_DIR" || \
    print_error "Fallo al descomprimir."

# Limpiar
rm -f "$ZIP_FILE"

# Habilitar extensión
print_status "Habilitando $EXTENSION_UUID"
gnome-extensions enable "$EXTENSION_UUID" || \
    print_error "No se pudo habilitar la extensión."

print_success "¡$EXTENSION_NAME instalada y habilitada!"

echo -e "\n\e[1m\e[33m[ATENCIÓN]\e[0m Reinicia GNOME Shell (Alt+F2 → r → Enter) o cierra y vuelve a iniciar sesión para aplicar cambios."
