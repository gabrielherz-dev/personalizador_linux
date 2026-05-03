#!/bin/bash

# --- CONFIGURACIÓN ---
CONTAINER_NAME="vscode-env"
CONTAINER_IMAGE="registry.opensuse.org/opensuse/tumbleweed:latest"
# Carpeta donde se guardarán plugins y configs de VS Code (Aislada del host)
CUSTOM_HOME="$HOME/.local/share/distrobox/vscode-home"
# Tu directorio de proyectos
WORKSPACE_DIR="/home/gherz/workspace"

echo "🚀 Iniciando configuración de VS Code en Distrobox para openSUSE Leap 16..."

# 1. Asegurar dependencias en el host
echo "📦 Verificando podman y distrobox en el sistema anfitrión..."
sudo zypper install -y podman distrobox

# 2. Crear carpetas necesarias
mkdir -p "$CUSTOM_HOME"
mkdir -p "$WORKSPACE_DIR"

# 3. Crear el contenedor
# --home: Aisla los plugins/config en la carpeta CUSTOM_HOME
# --volume: Mapea tu workspace real 1:1 dentro del contenedor
echo "🏗️ Creando contenedor '$CONTAINER_NAME' con home aislado..."
distrobox create --name "$CONTAINER_NAME" \
                 --image "$CONTAINER_IMAGE" \
                 --home "$CUSTOM_HOME" \
                 --volume "$WORKSPACE_DIR:$WORKSPACE_DIR" \
                 --yes

# 4. Instalar VS Code y herramientas dentro del contenedor
echo "📥 Instalando VS Code y dependencias de desarrollo..."
distrobox enter "$CONTAINER_NAME" -- bash -c "
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo zypper addrepo https://packages.microsoft.com/yumrepos/vscode vscode
    sudo zypper --gpg-auto-import-keys refresh
    # Instalamos code y dependencias gráficas necesarias para Electron
    sudo zypper install -y code git bash-completion libgbm1 libasound2 libxkbfile1
"

# 5. Exportar VS Code al menú de aplicaciones del host
echo "🔗 Exportando VS Code al sistema anfitrión..."
distrobox enter "$CONTAINER_NAME" -- distrobox-export --app code

echo "---"
echo "✅ ¡Configuración completada con éxito!"
echo "📍 Workspace: $WORKSPACE_DIR"
echo "🛡️ Plugins aislados en: $CUSTOM_HOME"
echo "💡 Ya puedes abrir 'Visual Studio Code' desde tu menú de aplicaciones."
