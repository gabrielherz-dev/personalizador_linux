##!/bin/bash

# Script para crear y cargar perfiles AppArmor básicos por subvolumen
# Incluye perfiles reforzados para ~/.ssh y ~/.gnupg en modo enforce
# Compatible con Debian 12

set -e

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse como root" >&2
    exit 1
fi

USER_NAME="${SUDO_USER:-$(logname)}"
APPARMOR_DIR="/etc/apparmor.d"

# Subvolúmenes normales (modo complain)
SUBVOLUMES=(
    "opt"
    "var/cache"
    "var/lib/lightdm"
    "var/lib/gdm"
    # "var/lib/libvirt/images"
    "var/log"
    "var/spool"
    "var/tmp"
    "var/www"
    "home/$USER_NAME/.local/share/flatpak"
    "home/$USER_NAME/var/lib/flatpak"
    "home/$USER_NAME/.mozilla"
)

echo "[*] Generando perfiles básicos en modo complain..."

for path in "${SUBVOLUMES[@]}"; do
    clean_name=$(echo "$path" | sed "s|/|.|g")
    profile_path="$APPARMOR_DIR/usr.subvolume.${clean_name}"

    echo "[+] Perfil: $profile_path"

    cat > "$profile_path" <<EOF
#include <tunables/global>

profile usr.subvolume.${clean_name} flags=(complain) {
  #include <abstractions/base>

  /$path/ r,
  /$path/** rwk,
  /$path/** ix,
}
EOF

    apparmor_parser -r "$profile_path"
done

echo "[*] Generando perfiles reforzados (modo enforce) para .ssh y .gnupg..."

# ~/.ssh
SSH_PROFILE="$APPARMOR_DIR/usr.subvolume.home.${USER_NAME}..ssh"
cat > "$SSH_PROFILE" <<EOF
#include <tunables/global>

profile usr.subvolume.home.${USER_NAME}..ssh {
  #include <abstractions/base>

  /home/$USER_NAME/.ssh/ r,
  /home/$USER_NAME/.ssh/** rw,

  deny /home/$USER_NAME/.ssh/** mrwx,
}
EOF

apparmor_parser -r "$SSH_PROFILE"

# ~/.gnupg
GNUPG_PROFILE="$APPARMOR_DIR/usr.subvolume.home.${USER_NAME}..gnupg"
cat > "$GNUPG_PROFILE" <<EOF
#include <tunables/global>

profile usr.subvolume.home.${USER_NAME}..gnupg {
  #include <abstractions/base>

  /home/$USER_NAME/.gnupg/ r,
  /home/$USER_NAME/.gnupg/** rw,

  deny /home/$USER_NAME/.gnupg/** mrwx,
}
EOF

apparmor_parser -r "$GNUPG_PROFILE"

echo "[✔] Todos los perfiles han sido creados y cargados."
echo "    - Los perfiles normales están en modo complain"
echo "    - Los perfiles de .ssh y .gnupg están en modo enforce"
# modo enforce para todos los perfiles normales
aa-enforce /etc/apparmor.d/usr.subvolume.*
