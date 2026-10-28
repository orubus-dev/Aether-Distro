#!/bin/bash
# AetherOS system action scripts — real functionality, invoked by aether-welcome via pkexec.
set -euo pipefail
ACTIONS="/usr/lib/aether/scripts"
case "${1:-}" in
  install-steam)
    dpkg --add-architecture i386 || true
    apt-get update -o Acquire::Retries=5
    apt-get install -y steam-libs-i386 2>/dev/null || apt-get install -y steam 2>/dev/null || true
    if [ ! -x /usr/bin/steam ] && [ ! -x /usr/lib/steam/steam ]; then
      curl -fsSL -o /tmp/steam.deb https://steamcdn-a.akamaihd.net/client/installer/steam.deb
      dpkg -i /tmp/steam.deb || apt-get install -fy
      rm -f /tmp/steam.deb
    fi
    echo "Steam installed." ;;
  install-bottles)
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo --system
    flatpak install -y --system flathub com.usebottles.bottles
    echo "Bottles installed — run Windows apps easily." ;;
  setup-waydroid)
    apt-get install -y waydroid 2>/dev/null || true
    modprobe binder_linux 2>/dev/null || true
    if [ ! -d /dev/binderfs ] && ! grep -qs binderfs /proc/filesystems; then
      echo "NOTE: binderfs missing — reboot into the Aether kernel (-aether) for Android support."
    fi
    waydroid init ${2:-} || waydroid init
    systemctl enable --now waydroid-container
    echo "Waydroid ready — launch it from the app grid." ;;
  install-lutris)
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo --system
    flatpak install -y --system flathub net.lutris.Lutris ;;
  install-libreoffice)
    apt-get update -o Acquire::Retries=5
    apt-get install -y libreoffice libreoffice-gtk3
    echo "LibreOffice installed." ;;
  install-gimp)
    apt-get update -o Acquire::Retries=5
    apt-get install -y gimp
    echo "GIMP installed." ;;
  install-nvidia)
    apt-get update -o Acquire::Retries=5
    apt-get install -y linux-headers-amd64 2>/dev/null || true
    apt-get install -y nvidia-driver firmware-nvidia-graphics
    echo "NVIDIA driver installed — reboot to activate." ;;
  system-update)
    apt-get update -o Acquire::Retries=5
    DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y
    flatpak update -y --system 2>/dev/null || true
    echo "System updated." ;;
  *)
    echo "usage: $0 {install-steam|install-bottles|setup-waydroid|install-lutris|install-libreoffice|install-gimp|install-nvidia|system-update}"; exit 1 ;;
esac
