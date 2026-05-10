#!/usr/bin/env bash

set -e

# =========================================================
# Fedora Kinoite + Toolbox + VS Code Flatpak
# Entorno de desarrollo integrado
# =========================================================

TOOLBOX_NAME="dev"
TOOLBOX_IMAGE="registry.fedoraproject.org/fedora-toolbox:40"

echo "🚀 Configurando entorno Toolbox para VS Code Flatpak..."
echo

# =========================================================
# 1. Crear toolbox
# =========================================================

if toolbox list | grep -q "$TOOLBOX_NAME"; then
    echo "ℹ️  Toolbox '$TOOLBOX_NAME' ya existe."
else
    echo "📦 Creando toolbox '$TOOLBOX_NAME'..."
    toolbox create \
        --container "$TOOLBOX_NAME" \
        --image "$TOOLBOX_IMAGE"
fi

# =========================================================
# 2. Instalar herramientas de desarrollo
# =========================================================

echo
echo "📦 Instalando paquetes de desarrollo..."

toolbox run -c "$TOOLBOX_NAME" sudo dnf install -y \
    gcc gcc-c++ clang \
    make cmake ninja-build meson \
    python3 python3-pip \
    nodejs npm yarnpkg \
    git git-lfs \
    rust cargo rustfmt \
    golang \
    java-21-openjdk-devel \
    openssl-devel zlib-devel \
    sqlite-devel \
    podman \
    buildah \
    tar gzip bzip2 unzip xz \
    which findutils diffutils patch \
    procps-ng hostname iproute \
    shadow-utils passwd \
    curl wget \
    vim nano neovim less \
    fish zsh tmux \
    glibc-langpack-en \
    flatpak-spawn

# =========================================================
# 3. Configurar shell por defecto (opcional)
# =========================================================

echo
echo "🐚 Configurando zsh como shell por defecto dentro del toolbox..."

toolbox run -c "$TOOLBOX_NAME" sh -c '
if command -v zsh >/dev/null; then
    chsh -s /usr/bin/zsh $USER || true
fi
'

# =========================================================
# 4. Crear wrapper para VS Code Flatpak
# =========================================================

echo
echo "🔧 Creando lanzador de VS Code..."

mkdir -p "$HOME/.local/bin"

cat > "$HOME/.local/bin/code-toolbox" <<EOF
#!/usr/bin/env bash
flatpak run com.visualstudio.code "\$@"
EOF

chmod +x "$HOME/.local/bin/code-toolbox"

# =========================================================
# 5. Configuración recomendada para VS Code
# =========================================================

VSCODE_SETTINGS="$HOME/.var/app/com.visualstudio.code/config/Code/User/settings.json"

mkdir -p "$(dirname "$VSCODE_SETTINGS")"

if [ ! -f "$VSCODE_SETTINGS" ]; then
    echo "{}" > "$VSCODE_SETTINGS"
fi

echo
echo "🛠️  Añadiendo perfil de terminal Toolbox a VS Code..."

python3 <<EOF
import json
from pathlib import Path

settings_path = Path("$VSCODE_SETTINGS")

with open(settings_path, "r") as f:
    try:
        settings = json.load(f)
    except:
        settings = {}

profiles = settings.get("terminal.integrated.profiles.linux", {})

profiles["Toolbox"] = {
    "path": "/usr/bin/flatpak-spawn",
    "args": [
        "--host",
        "toolbox",
        "enter",
        "$TOOLBOX_NAME"
    ]
}

settings["terminal.integrated.profiles.linux"] = profiles
settings["terminal.integrated.defaultProfile.linux"] = "Toolbox"

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)

print("✅ settings.json actualizado.")
EOF

# =========================================================
# 6. Permisos Flatpak necesarios
# =========================================================

echo
echo "🔐 Aplicando permisos Flatpak recomendados..."

flatpak override --user --filesystem=home com.visualstudio.code
flatpak override --user --share=network com.visualstudio.code
flatpak override --user --socket=wayland com.visualstudio.code
flatpak override --user --socket=fallback-x11 com.visualstudio.code
flatpak override --user --talk-name=org.freedesktop.Flatpak com.visualstudio.code
flatpak override --user --filesystem=xdg-run/podman com.visualstudio.code

# =========================================================
# 7. Final
# =========================================================

echo
echo "========================================================="
echo "✅ Entorno listo"
echo "========================================================="
echo
echo "Toolbox:"
echo "  toolbox enter $TOOLBOX_NAME"
echo
echo "VS Code:"
echo "  flatpak run com.visualstudio.code"
echo
echo "La terminal integrada de VS Code abrirá automáticamente"
echo "dentro del toolbox."
echo
echo "Todo lo que compiles desde VS Code se ejecutará dentro"
echo "del contenedor Toolbox."
echo
