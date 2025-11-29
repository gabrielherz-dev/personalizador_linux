###############
#### NO PROBADO
###############
## !/bin/bash
## Clase para la instalación de aplicaciones relacionadas con el gestor i3wm
##
#source App.class.sh
#source constantes.sh
#
#declare -A batteryApp
#
#batteryApp.new(){
#local self=$1
##Tema a usar para personalizar la apariencia
#local tema=$2
##Declaro mi propio this como un arreglo global de propiedades
#declare -gA $self
##El equivalente a super() en otros lenguajes, heredo los atributos y métodos de mi clase padre
#App.new "$self"
##Creo un puntero para tratar el atributo
#declare -n rself="$self"
##Borro los atributos de mi clase padre, solo me interesan los de esta clase hija
#unset self
#rself["tlp"]="tlp"
#rself["tlp-rdw"]="tlp-rdw"
#rself["powertop"]="powertop"
#}
## Métodos privados
#configTlp(){
#if [[ $( "$self.checkiInstallation" "tlp" ) ]]; then
#echo ">> Habilitando y configurando TLP..."
#systemctl enable tlp
#systemctl start tlp
#systemctl mask systemd-rfkill.service
#systemctl mask systemd-rfkill.socket
#
#echo ">> Ejecutando powertop --auto-tune (temporal hasta reinicio)..."
#powertop --auto-tune
#
#echo ">> Instalando auto-cpufreq desde GitHub..."
#if ! command -v auto-cpufreq &>/dev/null; then
#git clone https://github.com/AdnanHodzic/auto-cpufreq.git /opt/auto-cpufreq
#cd /opt/auto-cpufreq || exit
#./auto-cpufreq-installer --install
#else
#echo "  - auto-cpufreq ya está instalado."
#fi
#
#echo ">> Habilitando auto-cpufreq como servicio..."
#auto-cpufreq --install
#systemctl enable auto-cpufreq
#systemctl start auto-cpufreq
#
#echo ">> Comprobando estado de servicios:"
#systemctl status tlp | grep Active
#systemctl status auto-cpufreq | grep Active
#
#echo "======== OPTIMIZACIÓN COMPLETADA ========"
#echo "Log generado en: $LOGFILE"
#fi
#}
## Métodos heredados
#batteryApp.installConfig(){
#configTlp
#}
#
#batteryApp.install(){
#apt install --y $1 | tee -a $LOG_INSTALLATION
#}
#
#batteryApp.checkInstall(){
#if[[ -n $( command -n "$1" ) ]]; then
#echo true
#fi
#}
#
