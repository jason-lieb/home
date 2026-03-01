#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

usage() {
  cat <<'EOF'
Usage:
  sudo ./scripts/linux-migration/ubuntu.sh [--user USER] [--host desktop|laptop|mini|z560] [--passwordless-sudo]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user) TARGET_USER="$2"; shift 2 ;;
    --host) TARGET_HOST="$2"; shift 2 ;;
    --passwordless-sudo) ENABLE_PASSWORDLESS_SUDO=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

require_root

log "Updating apt repositories"
apt-get update
apt-get -y upgrade

log "Installing Ubuntu packages"
apt-get install -y \
  sddm kde-plasma-desktop kdeconnect \
  dolphin okular gwenview \
  network-manager pipewire wireplumber libspa-0.2-bluetooth \
  bluez bluedevil \
  docker.io ufw flatpak syncthing \
  steam-installer \
  fish git gh direnv ffmpeg make htop jq lsof wget zoxide \
  nodejs npm \
  dolphin-emu mgba-qt retroarch \
  wl-clipboard gparted

if ! apt-get install -y libfuse2; then
  apt-get install -y libfuse2t64 || true
fi

if ! command -v pnpm >/dev/null 2>&1; then
  npm install -g pnpm || true
fi
if ! command -v bun >/dev/null 2>&1; then
  warn "bun not installed (not in default Ubuntu repos). Install separately if needed."
fi

warn "PrimeHack may require manual install on Ubuntu (PPA/build/manual package)."
warn "Brave/Chrome/Vivaldi/GitHub Desktop/Cursor may require vendor repos, debs, or flatpak."

log "Enabling core services"
enable_service NetworkManager.service
enable_service sddm.service

configure_timezone_locale
configure_hosts_entry
configure_bluetooth_service
configure_docker_group
configure_firewall_ufw
configure_flatpak
configure_syncthing
configure_user_env
set_fish_shell
configure_mime_defaults
configure_autostart
configure_kde_desktop_entries
configure_passwordless_sudo

log "Ubuntu migration bootstrap complete for host=${TARGET_HOST} user=${TARGET_USER}"
print_syncthing_manual_steps
print_emulator_notes
