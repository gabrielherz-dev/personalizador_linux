
#!/bin/bash
set -e

echo "Configurando el repositorio oficial de WezTerm..."

# Añadir la clave GPG al sistema de confianza
curl -fsSL https://apt.fury.io/wez/gpg.key |  gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg

# Crear el archivo de repositorio
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' |
   tee /etc/apt/sources.list.d/wezterm.list

# Ajustar permisos
 chmod 644 /usr/share/keyrings/wezterm-fury.gpg

echo "Actualizando repositorios..."
 apt update

echo "Instalando WezTerm (estable)..."
 apt install -y wezterm

echo "WezTerm instalado exitosamente."
