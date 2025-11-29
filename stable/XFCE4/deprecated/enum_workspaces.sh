#!/bin/bash
# Muestra la lista de workspaces numerados y resalta el actual

current_ws=$(wmctrl -d | awk '$2=="*"{print $1}')
total_ws=$(wmctrl -d | wc -l)

output=""
for ((i=0; i<total_ws; i++)); do
    if [[ $i -eq $current_ws ]]; then
        output+="[${i}] "
    else
        output+="${i} "
    fi
done

echo "$output"

