#!/usr/bin/env bash

set -e

CONTAINER_NAME="dev-env"
CONTAINER_HOME="$HOME/.distrobox/$CONTAINER_NAME"

echo "🚀 Creando entorno de desarrollo para Fedora Kinoite..."

mkdir -p "$CONTAINER_HOME"

# Crear contenedor
distrobox create \
  --name "$CONTAINER_NAME" \
  --image registry.fedoraproject.org/fedora-toolbox:40 \
  --home "$CONTAINER_HOME" \
  --yes

echo "📦 Instalando herramientas de desarrollo..."

distrobox enter "$CONTAINER_NAME" -- sudo dnf install -y \
  gcc gcc-c++ clang make cmake ninja-build \
  python3 python3-pip \
  nodejs npm \
  git git-lfs \
  rust cargo \
  golang \
  java-21-openjdk-devel \
  openssl-devel zlib-devel \
  tar gzip bzip2 unzip xz \
  which findutils diffutils patch \
  procps-ng hostname iproute \
  shadow-utils passwd \
  curl wget \
  vim nano less \
  zsh fish \
  glibc-langpack-en

echo "🔧 Exportando utilidades al host..."

distrobox enter "$CONTAINER_NAME" -- distrobox-export --bin /usr/bin/fish
distrobox enter "$CONTAINER_NAME" -- distrobox-export --bin /usr/bin/zsh

echo "✅ Contenedor listo."
echo
echo "Entrar:"
echo "distrobox enter $CONTAINER_NAME"

# Permisos flatpak para vscode
# Para VSCODE y su conexión con podman (distrobox/toolbx)
flatpak override --user --filesystem=home com.visualstudio.code
flatpak override --user --share=network com.visualstudio.code
flatpak override --user --socket=fallback-x11 com.visualstudio.code
flatpak override --user --socket=wayland com.visualstudio.code
flatpak override --user --talk-name=org.freedesktop.Flatpak com.visualstudio.code
flatpak override --user --filesystem=xdg-run/podman com.visualstudio.code

