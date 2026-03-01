#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

usage() {
  cat <<'EOF'
Usage:
  sudo ./scripts/linux-migration/arch.sh [--user USER] [--host desktop|laptop|mini|z560] [--passwordless-sudo]
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

log "Installing Arch packages"
pacman -Syu --noconfirm

pacman -S --needed --noconfirm \
  base-devel \
  sddm plasma-desktop kdeplasma-addons kdeconnect \
  dolphin okular gwenview \
  networkmanager pipewire wireplumber pipewire-alsa pipewire-pulse \
  bluez bluez-utils bluedevil \
  docker ufw flatpak syncthing \
  steam lib32-mesa \
  fish git github-cli direnv ffmpeg make htop jq lsof wget zoxide bat just \
  nodejs npm pnpm bun \
  dolphin-emu mgba retroarch \
  wl-clipboard gparted

# Optional desktop/browser packages that may live in AUR on many setups.
if command -v yay >/dev/null 2>&1; then
  log "Installing optional AUR packages with yay"
  sudo -u "${TARGET_USER}" yay -S --needed --noconfirm \
    vivaldi vivaldi-ffmpeg-codecs google-chrome brave-bin github-desktop-bin \
    obsidian cursor-bin primehack || true
else
  warn "AUR helper not found; skipping vivaldi/chrome/brave/github-desktop/obsidian/cursor/primehack"
fi

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

log "Arch migration bootstrap complete for host=${TARGET_HOST} user=${TARGET_USER}"
print_syncthing_manual_steps
print_emulator_notes
