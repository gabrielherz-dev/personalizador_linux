
#!/usr/bin/env bash
set -euo pipefail

EXT_UUID="tiling-assistant@fthx"
EXT_ID="3733"
EXT_NAME="Tiling Assistant"

# util
err(){ echo -e "\e[31mERROR:\e[0m $*" >&2; exit 1; }
info(){ echo -e "\e[34m[INFO]\e[0m $*"; }
ok(){ echo -e "\e[32m[OK]\e[0m $*"; }

# 1) versión de GNOME Shell
GNOME_VER=$(gnome-shell --version 2>/dev/null | grep -oP '[0-9]+' | head -1 || true)
[ -n "$GNOME_VER" ] || err "No puedo detectar gnome-shell. ¿Estás en GNOME?"

info "GNOME Shell version: $GNOME_VER"

# 2) Obtener pk (version_tag) desde extension-query
RAW=$(curl -s "https://extensions.gnome.org/extension-query/?search=${EXT_UUID}")
# extraer el objeto que coincida con el uuid
PK=$(echo "$RAW" | jq -r ".extensions[] | select(.uuid==\"$EXT_UUID\") | .shell_version_map.\"$GNOME_VER\".pk" 2>/dev/null || true)

if [ -z "$PK" ] || [ "$PK" = "null" ]; then
  echo "No se ha encontrado version_tag (pk) para GNOME $GNOME_VER."
  echo "Salida parcial de shell_version_map:"
  echo "$RAW" | jq -r ".extensions[] | select(.uuid==\"$EXT_UUID\") | .shell_version_map"
  err "No hay pk para tu versión de GNOME o la extensión no soporta esta versión."
fi

info "version_tag (pk) encontrado: $PK"

# 3) construir URL y descargar con headers 'Referer' y 'User-Agent'
DOWNLOAD_URL="https://extensions.gnome.org/download-extension/${EXT_UUID}.shell-extension.zip?version_tag=${PK}"
TMPZIP="/tmp/${EXT_UUID}-${PK}.zip"

info "Descargando desde: $DOWNLOAD_URL (añadiendo Referer y User-Agent)"
# header Referer = la página de la extensión (usado por el sitio)
REFERER="https://extensions.gnome.org/extension/${EXT_ID}/"
# user agent tipo navegador
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"

# usa -f para que curl falle con código >=400
if ! curl -fL -A "$UA" -H "Referer: $REFERER" -H "Accept: */*" "$DOWNLOAD_URL" -o "$TMPZIP"; then
  rm -f "$TMPZIP" || true
  err "Fallo al descargar: el servidor devolvió 4xx/5xx. Posibles causas: pk inválido, pk expirado o falta de compatibilidad."
fi

ok "ZIP descargado a $TMPZIP"

# 4) descomprimir en el directorio correcto
EXT_DIR="$HOME/.local/share/gnome-shell/extensions/${EXT_UUID}"
mkdir -p "$EXT_DIR"
info "Descomprimiendo en $EXT_DIR"
unzip -o "$TMPZIP" -d "$EXT_DIR" >/dev/null || err "Fallo al descomprimir."

rm -f "$TMPZIP"
ok "Extensión instalada en $EXT_DIR"

# 5) Habilitar
if command -v gnome-extensions >/dev/null 2>&1; then
  gnome-extensions enable "$EXT_UUID" || info "gnome-extensions no pudo habilitar (quizá necesites reiniciar shell)."
else
  info "gnome-extensions no está disponible; habilita manualmente o instala gnome-extensions-app."
fi

echo
ok "Instalación finalizada. Reinicia GNOME Shell (Alt+F2 → r → Enter) o vuelve a iniciar sesión."
