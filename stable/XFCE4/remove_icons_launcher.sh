#!/bin/bash
#set -euo pipefail

# Detectar todos los paneles
panels=$(xfconf-query -c xfce4-panel -p /panels | tr -d '[],')

for panel in $panels; do
    echo "🔍 Revisando panel: $panel"
    
    # Obtener lista de plugins de este panel
    plugins=$(xfconf-query -c xfce4-panel -p /panels/panel-$panel/plugin-ids | tr -d '[],')

    # Nueva lista sin launchers
    new_list=()
    for pid in $plugins; do
        # Detectar si el plugin es "launcher" en su definición
        plugin_type=$(xfconf-query -c xfce4-panel -p /plugins/plugin-$pid 2>/dev/null || echo "")

        if [[ "$plugin_type" == "launcher" ]]; then
            echo "🗑 Eliminando plugin launcher con ID: $pid"
            # Borrar todas las propiedades de ese plugin
            xfconf-query -c xfce4-panel -p /plugins/plugin-$pid -r -R
        else
            new_list+=($pid)
        fi
    done

    # Reescribir la lista de plugins sin los launchers
    if [[ ${#new_list[@]} -gt 0 ]]; then
        xfconf-query -c xfce4-panel -p /panels/panel-$panel/plugin-ids \
            $(for id in "${new_list[@]}"; do echo -n "-t int -s $id "; done)
    else
        xfconf-query -c xfce4-panel -p /panels/panel-$panel/plugin-ids -r
    fi
done

# Recargar panel
xfce4-panel -r

echo "✅ Todos los launchers han sido eliminados."

