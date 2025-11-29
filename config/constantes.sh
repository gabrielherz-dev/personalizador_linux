readonly THINKPAD_THEME="THINKPAD"
readonly DEBIAN_THEME="DEBIAN"
readonly LOG_INSTALLATION="installation.log"
#directorio donde se guardará la configuración del entorno de escritorio
readonly TARGET_USER="$(logname)"
readonly TARGET_HOME="/home/$TARGET_USER"
#Directorio desde donde procede la installación
readonly RUTA_ORIGEN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
