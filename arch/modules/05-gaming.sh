#!/bin/bash
set -euo pipefail

echo "=== Gaming Configuration ==="

PRIMEHACK_BIN=""
if command -v dolphin-emu-primehack >/dev/null 2>&1; then
    PRIMEHACK_BIN="dolphin-emu-primehack"
elif command -v primehack >/dev/null 2>&1; then
    PRIMEHACK_BIN="primehack"
fi

# ============================================
# Dolphin Emulator udev Rules
# ============================================
echo "Configuring Dolphin udev rules..."

# Copy udev rules for GameCube controller adapter
if [[ -f /usr/lib/udev/rules.d/51-dolphin-emu.rules ]]; then
    sudo cp /usr/lib/udev/rules.d/51-dolphin-emu.rules /etc/udev/rules.d/
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    echo "Dolphin udev rules installed"
else
    echo "WARNING: Dolphin udev rules not found. Install dolphin-emu first."
fi

# ============================================
# GCC Adapter Overclocking
# ============================================
echo "Configuring GCC adapter overclocking..."

# Load kernel module if available
if modinfo gcadapter_oc &> /dev/null; then
    sudo modprobe gcadapter_oc || true

    # Add to modules-load.d for boot
    echo "gcadapter_oc" | sudo tee /etc/modules-load.d/gcadapter-oc.conf > /dev/null
    echo "GCC adapter overclock module configured"
else
    echo "WARNING: gcadapter_oc module not found. Install gcadapter-oc-kmod-dkms from AUR."
fi

# ============================================
# PrimeHack Wrapper Script
# ============================================
echo "Creating PrimeHack wrapper script..."

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
echo "PrimeHack wrapper installed at /usr/local/bin/primehack"
if [[ -z "$PRIMEHACK_BIN" ]]; then
    echo "WARNING: PrimeHack package not currently installed."
fi

# ============================================
# Desktop Entries
# ============================================
echo "Creating desktop entries..."

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
echo "Setting up AM2R via Flatpak..."

# Add Flathub remote if not present
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install AM2R Launcher
flatpak install -y flathub io.github.am2r_community_developers.AM2RLauncher || {
    echo "AM2R Launcher installation failed or already installed"
}

# Grant udev access for controller support
flatpak override --user --filesystem=/run/udev:ro io.github.am2r_community_developers.AM2RLauncher

echo "AM2R Launcher configured"

# ============================================
# RetroArch Configuration Notes
# ============================================
echo ""
echo "RetroArch Notes:"
echo "- BSNES HD core should be available via libretro-bsnes-hd-git"
echo "- Configure RetroArch through the application GUI"
echo "- Saves sync via Syncthing at ~/Documents/snes"

echo ""
echo "=== Gaming Configuration Complete ==="
