#!/bin/bash
# Muestra la lista de workspaces numerados y resalta el actual
set -euo pipefail

# Ruta del CSS de usuario
CSS_FILE="$HOME/.config/gtk-3.0/gtk.css"

mkdir -p "$(dirname "$CSS_FILE")"

cat > "$CSS_FILE" <<'EOF'
/* ==== Estilos personalizados para XFCE4 Workspace Switcher ==== */

/* Todos los botones del switcher: texto más visible */
.xfce4-panel  button {
    font-weight: bold;       /* negrita */
    padding: 2px 2px;        /* espacio interno */
    border-radius: 0px;      /* bordes suavizados */
}

/* Workspace activo (seleccionado): borde blanco */
.xfce4-panel  button:checked,
.xfce4-panel  button:active {
    border: 1px solid #ffffff;
    border-radius: 0px;
    box-shadow: 0 0 2px rgba(255, 255, 255, 0.6); /* efecto brillo */
}
EOF

echo "CSS aplicado en: $CSS_FILE"
echo "Reiniciando panel..."
xfce4-panel -r
