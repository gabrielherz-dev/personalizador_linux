#!/bin/bash

# Nombre de la extensión y su ID en la web de GNOME Extensions
EXTENSION_NAME="Tiling Assistant (fthx)"
EXTENSION_UUID="tiling-assistant@fthx"
# ID de la extensión en extensions.gnome.org
EXTENSION_ID="3733" 

# --- Funciones de Utilidad ---

# Función para imprimir mensajes de estado
print_status() {
    echo -e "\n\e[1m\e[34m[INFO]\e[0m $1"
}

# Función para imprimir mensajes de éxito
print_success() {
    echo -e "\n\e[1m\e[32m[ÉXITO]\e[0m $1"
}

# Función para imprimir mensajes de error
print_error() {
    echo -e "\n\e[1m\e[31m[ERROR]\e[0m $1"
    exit 1
}

# --- Inicio del Script ---

print_status "Iniciando la instalación de la extensión '$EXTENSION_NAME' (UUID: $EXTENSION_UUID)..."

# 1. Verificar si GNOME Shell está instalado
if ! command -v gnome-shell &> /dev/null; then
    print_error "Parece que GNOME Shell no está instalado. Este script solo funciona en entornos GNOME."
fi

# 2. Instalar dependencias necesarias
print_status "Comprobando e instalando dependencias necesarias (curl, unzip, gnome-shell-extensions, chrome-gnome-shell)..."
sudo apt update
sudo apt install -y curl unzip chrome-gnome-shell gnome-shell-extensions || print_error "Fallo al instalar las dependencias con apt."

# 3. Directorio de destino para las extensiones de GNOME
EXTENSION_DIR="$HOME/.local/share/gnome-shell/extensions/$EXTENSION_UUID"
EXTENSION_ZIP="extension.zip"

# 4. Descargar la extensión
# Usamos el API de extensions.gnome.org para descargar la última versión compatible con tu shell.
print_status "Descargando el archivo ZIP de la extensión (ID $EXTENSION_ID) desde extensions.gnome.org..."
# El comando curl obtiene la versión más reciente compatible con tu shell de GNOME usando el UUID.
curl -s -L "https://extensions.gnome.org/download-extension/$EXTENSION_UUID.shell-extension.zip?version_tag=-1" -o "$EXTENSION_ZIP"

if [ $? -ne 0 ]; then
    print_error "Fallo al descargar la extensión. Verifica tu conexión o si la ID ($EXTENSION_UUID) es correcta."
fi

# 5. Crear el directorio de destino y descomprimir
print_status "Creando el directorio de destino: $EXTENSION_DIR"
mkdir -p "$EXTENSION_DIR" || print_error "Fallo al crear el directorio de destino."

print_status "Descomprimiendo la extensión en $EXTENSION_DIR..."
unzip -q "$EXTENSION_ZIP" -d "$EXTENSION_DIR"
if [ $? -ne 0 ]; then
    print_error "Fallo al descomprimir el archivo ZIP. Archivo corrupto o permisos incorrectos."
fi

# 6. Limpiar
print_status "Limpiando archivos temporales..."
rm "$EXTENSION_ZIP"

# 7. Habilitar la extensión
print_status "Habilitando la extensión..."
gnome-extensions enable "$EXTENSION_UUID" || print_error "Fallo al habilitar la extensión. Asegúrate de que tu versión de GNOME Shell es compatible con esta extensión."

# 8. Reiniciar GNOME Shell o aconsejar al usuario
print_success "La extensión '$EXTENSION_NAME' ha sido instalada y habilitada."
echo -e "\n\e[1m\e[33m[ATENCIÓN]\e[0m Para que los cambios surtan efecto, debes \e[1mreiniciar GNOME Shell\e[0m (presionando \e[1mAlt + F2\e[0m, escribiendo \e[1mr\e[0m y presionando \e[1mEnter\e[0m) o \e[1mcerrar y volver a iniciar sesión\e[0m."
