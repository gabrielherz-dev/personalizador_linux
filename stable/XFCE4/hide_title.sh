
#!/bin/bash
set -euo pipefail

# Script para ocultar/mostrar los títulos de las ventanas en XFCE4
# Autor: ChatGPT

# Función para ocultar los títulos
ocultar_titulos() {
    echo "🔹 Ocultando títulos de las ventanas..."
    xfconf-query -c xfwm4 -p /general/titleless_maximize -s true
    #xfconf-query -c xfwm4 -p /general/titleless_workspaces -s true || true
    # Opcional: eliminar decoración en ventanas nuevas
    #xfconf-query -c xfwm4 -p /general/show_frame -s false
}

# Función para restaurar los títulos
mostrar_titulos() {
    echo "🔹 Restaurando títulos de las ventanas..."
    xfconf-query -c xfwm4 -p /general/titleless_maximize -s false
    xfconf-query -c xfwm4 -p /general/titleless_workspaces -s false || true
    xfconf-query -c xfwm4 -p /general/show_frame -s true
}
ocultar_titulos

#case "${1:-}" in
#    ocultar)
#        ocultar_titulos
#        ;;
#    mostrar)
#        mostrar_titulos
#        ;;
#    *)
#        echo "Uso: $0 {ocultar|mostrar}"
#        exit 1
#        ;;
#esac

echo "✅ Listo."
