#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

msg "=== Gaming Configuration ==="

# ============================================
# Gaming Packages
# ============================================
msg "Installing gaming packages..."

GAMING_OFFICIAL=(
    steam dolphin-emu mgba-qt retroarch lib32-gperftools
)

GAMING_AUR=(
    primehack-dolphin-emu gcadapter-oc-kmod-dkms libretro-bsnes-hd-git
)

yay -S --needed --noconfirm "${GAMING_OFFICIAL[@]}" "${GAMING_AUR[@]}"

PRIMEHACK_BIN=""
if command -v dolphin-emu-primehack >/dev/null 2>&1; then
    PRIMEHACK_BIN="dolphin-emu-primehack"
elif command -v primehack >/dev/null 2>&1; then
    PRIMEHACK_BIN="primehack"
fi

# ============================================
# Dolphin Emulator udev Rules
# ============================================
msg "Configuring Dolphin udev rules..."

# Copy udev rules for GameCube controller adapter
if [[ -f /usr/lib/udev/rules.d/51-dolphin-emu.rules ]]; then
    sudo cp /usr/lib/udev/rules.d/51-dolphin-emu.rules /etc/udev/rules.d/
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    msg "Dolphin udev rules installed"
else
    msg "WARNING: Dolphin udev rules not found. Install dolphin-emu first."
fi

# ============================================
# GCC Adapter Overclocking
# ============================================
msg "Configuring GCC adapter overclocking..."

# Load kernel module if available
if modinfo gcadapter_oc &> /dev/null; then
    sudo modprobe gcadapter_oc || true

    # Add to modules-load.d for boot
    echo "gcadapter_oc" | sudo tee /etc/modules-load.d/gcadapter-oc.conf > /dev/null
    msg "GCC adapter overclock module configured"
else
    msg "WARNING: gcadapter_oc module not found. Install gcadapter-oc-kmod-dkms from AUR."
fi

# ============================================
# PrimeHack Wrapper Script
# ============================================
msg "Creating PrimeHack wrapper script..."

sudo tee /usr/local/bin/primehack > /dev/null << 'PRIMEHACK'
#!/bin/bash
if command -v dolphin-emu-primehack >/dev/null 2>&1; then
  exec dolphin-emu-primehack -u "$HOME/.local/share/primehack" "$@"
elif command -v primehack >/dev/null 2>&1; then
  exec primehack -u "$HOME/.local/share/primehack" "$@"
else
  echo "PrimeHack binary not found (expected dolphin-emu-primehack or primehack)" >&2
  exit 1
fi
PRIMEHACK

sudo chmod +x /usr/local/bin/primehack
msg "PrimeHack wrapper installed at /usr/local/bin/primehack"
if [[ -z "$PRIMEHACK_BIN" ]]; then
    msg "WARNING: PrimeHack package not currently installed."
fi

# ============================================
# Desktop Entries
# ============================================
msg "Creating desktop entries..."

mkdir -p "$HOME/.local/share/applications"

# PrimeHack desktop entry
cat > "$HOME/.local/share/applications/primehack.desktop" << 'PRIMEHACKDESKTOP'
[Desktop Entry]
Name=PrimeHack
Comment=Metroid Prime emulator (Dolphin fork)
Exec=/usr/local/bin/primehack
Icon=dolphin-emu
Type=Application
Categories=Game;Emulator;
Keywords=metroid;prime;dolphin;emulator;gamecube;wii;
PRIMEHACKDESKTOP

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# ============================================
# AM2R Flatpak Installation
# ============================================
msg "Setting up AM2R via Flatpak..."

# Add Flathub remote if not present
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install AM2R Launcher
flatpak install -y flathub io.github.am2r_community_developers.AM2RLauncher || {
    msg "AM2R Launcher installation failed or already installed"
}

# Grant udev access for controller support
flatpak override --user --filesystem=/run/udev:ro io.github.am2r_community_developers.AM2RLauncher

msg "AM2R Launcher configured"

# ============================================
# RetroArch Configuration Notes
# ============================================
msg ""
msg "RetroArch Notes:"
msg "- BSNES HD core should be available via libretro-bsnes-hd-git"
msg "- Configure RetroArch through the application GUI"
msg "- Saves sync via Syncthing at ~/Documents/snes"

msg ""
msg "=== Gaming Configuration Complete ==="
