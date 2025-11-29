#!/bin/bash
set -e

echo "🔋 Instalando paquetes necesarios..."
apt update
apt install -y tlp tlp-rdw tp-smapi-dkms acpi-call-dkms

echo "🛑 Desactivando power-profiles-daemon para evitar conflictos con TLP..."
 systemctl mask power-profiles-daemon
 systemctl stop power-profiles-daemon

echo "⚙️ Configurando /etc/tlp.conf..."
tee /etc/tlp.conf >/dev/null <<'EOF'
TLP_DEFAULT_MODE=BAT
TLP_PERSISTENT_DEFAULT=1

CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_SCALING_GOVERNOR_ON_AC=performance

CPU_ENERGY_PERF_POLICY_ON_BAT=power
CPU_ENERGY_PERF_POLICY_ON_AC=performance

SCHED_POWERSAVE_ON_BAT=1
SCHED_POWERSAVE_ON_AC=0

DISK_DEVICES="sda sdb nvme0n1"
DISK_APM_LEVEL_ON_BAT="128 128 128"
DISK_APM_LEVEL_ON_AC="254 254 254"
DISK_IOSCHED="mq-deadline"

USB_AUTOSUSPEND=1
USB_BLACKLIST_BTUSB=0
USB_EXCLUDE_AUDIO=1

RUNTIME_PM_ON_BAT=auto
RUNTIME_PM_ON_AC=on

PCIE_ASPM_ON_BAT=powersupersave
PCIE_ASPM_ON_AC=performance

START_CHARGE_THRESH_BAT0=40
STOP_CHARGE_THRESH_BAT0=80
EOF

echo "✅ Habilitando y arrancando TLP..."
systemctl enable tlp
 systemctl start tlp

echo "📊 Estado de TLP:"
tlp-stat -s
