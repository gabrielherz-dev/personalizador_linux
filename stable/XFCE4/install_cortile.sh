
#!/usr/bin/env bash
set -euo pipefail

# Instalador de Cortile (Debian 12/13, XFCE4)
# - Si se ejecuta como root: instalación global (/usr/local/bin, /etc/xdg/autostart)
# - Si se ejecuta como usuario normal: instalación local (~/.local/bin, ~/.config/autostart)

umask 022

is_root() { [ "$(id -u)" -eq 0 ]; }

# ---------------- Dependencias ----------------
need_cmds=(wget jq tar)

have_all_deps=true
for c in "${need_cmds[@]}"; do
  if ! command -v "$c" >/dev/null 2>&1; then
    have_all_deps=false
    missing+=("$c")
  fi
done

if ! $have_all_deps; then
  if is_root; then
    echo "Instalando dependencias: ${missing[*]} ..."
    apt-get update -y
    apt-get install -y "${missing[@]}"
  else
    echo "Faltan dependencias: ${missing[*]}"
    echo "Instálalas o ejecuta este script como root para instalación global."
    exit 1
  fi
fi

# ---------------- Rutas según contexto ----------------
if is_root; then
  INSTALL_DIR="/usr/local/bin"
  AUTOSTART_DIR="/etc/xdg/autostart"
else
  INSTALL_DIR="$HOME/.local/bin"
  AUTOSTART_DIR="$HOME/.config/autostart"
fi

mkdir -p "$INSTALL_DIR" "$AUTOSTART_DIR"

# ---------------- Descargar y extraer ----------------
echo "Descargando la última versión de Cortile..."
DOWNLOAD_URL="$(wget -qO- https://api.github.com/repos/leukipp/cortile/releases/latest \
  | jq -r '.assets[] | select(.name|test("linux_amd64.*\\.tar\\.gz$")) | .browser_download_url' \
  | head -n1)"

if [ -z "${DOWNLOAD_URL:-}" ]; then
  echo "No se pudo determinar la URL de descarga para linux_amd64."
  exit 1
fi

# Extraer directamente en el directorio de instalación
wget -qO- "$DOWNLOAD_URL" | tar -xz -C "$INSTALL_DIR"

# ---------------- Normalizar nombre y permisos ----------------
# Buscar el binario recién extraído (puede venir con sufijo de versión)
BIN_CANDIDATE="$(find "$INSTALL_DIR" -maxdepth 1 -type f -name 'cortile*' | head -n1)"
if [ -z "${BIN_CANDIDATE:-}" ]; then
  echo "No se encontró el binario tras la extracción."
  exit 1
fi

chmod 0755 "$BIN_CANDIDATE"

# Enlazar a nombre estable 'cortile'
ln -sf "$BIN_CANDIDATE" "$INSTALL_DIR/cortile"
BIN="$INSTALL_DIR/cortile"

# Propietario correcto en instalación global
if is_root; then
  chown root:root "$BIN_CANDIDATE" "$BIN"
fi

# ---------------- PATH para instalación local ----------------
if ! is_root; then
  case ":$PATH:" in
    *":$INSTALL_DIR:"*) : ;;  # ya está en PATH
    *) echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$HOME/.bashrc";;
  esac
fi

# ---------------- Autostart ----------------
DESKTOP_FILE="$AUTOSTART_DIR/cortile.desktop"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=Cortile
Comment=Auto-tiling para XFCE4
Exec=$BIN
TryExec=cortile
OnlyShowIn=XFCE;
X-GNOME-Autostart-enabled=true
X-KDE-autostart-after=panel
Terminal=false
EOF

# Permisos apropiados del .desktop
if is_root; then
  chmod 0644 "$DESKTOP_FILE"
  chown root:root "$DESKTOP_FILE"
else
  chmod 0644 "$DESKTOP_FILE"
fi

echo
echo "✅ Instalación completada."
echo "   Binario: $BIN"
if is_root; then
  echo "   Autostart global: $DESKTOP_FILE (para todos los usuarios XFCE)"
else
  echo "   Autostart de usuario: $DESKTOP_FILE"
fi
echo "   Se ejecutará automáticamente al iniciar sesión en XFCE."
echo
echo "   Para probar ahora: \"$BIN\" &"
