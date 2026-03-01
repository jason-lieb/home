#!/bin/bash
set -euo pipefail

echo "=== Package Installation ==="

OFFICIAL_PACKAGES=(
    fish bash git base-devel openssh
    bat htop jq wget ffmpeg make lsof zoxide lazygit lf tokei just github-cli
    docker docker-compose flatpak usbutils ufw bluez bluez-utils
    pipewire-alsa pipewire-pulse wireplumber lib32-mesa
    plasma-meta sddm dolphin okular gwenview bluedevil kcalc krdc kdeconnect
    plasma-browser-integration ksshaskpass kcolorchooser filelight
    firefox vivaldi
    pnpm bun direnv
    steam dolphin-emu mgba-qt retroarch lib32-gperftools
    aws-cli-v2 gparted
)

AUR_PACKAGES=(
    brave-bin google-chrome ghostty obsidian github-desktop-bin
    visual-studio-code-bin vivaldi-ffmpeg-codecs syncthing primehack-dolphin-emu
    gcadapter-oc-kmod-dkms wl-clipboard libretro-bsnes-hd-git
)

# Install yay if not present
install_yay() {
    if command -v yay &> /dev/null; then
        echo "yay is already installed"
        return 0
    fi

    echo "Installing yay..."
    local temp_dir
    temp_dir=$(mktemp -d)
    cd "$temp_dir"

    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm

    cd /
    rm -rf "$temp_dir"
    echo "yay installed successfully"
}

install_package_group() {
    local label="$1"
    shift
    local packages=("$@")

    if [[ ${#packages[@]} -eq 0 ]]; then
        echo "No packages defined for ${label}"
        return 0
    fi

    echo "Installing ${#packages[@]} packages for ${label}..."
    yay -S --needed --noconfirm "${packages[@]}"
}

# Update system first
echo "Updating system packages..."
sudo pacman -Syu --noconfirm

# Install yay
install_yay

# Install official packages
echo ""
echo "Installing official repository packages..."
install_package_group "official repositories" "${OFFICIAL_PACKAGES[@]}"

# Install AUR packages
echo ""
echo "Installing AUR packages..."
install_package_group "AUR" "${AUR_PACKAGES[@]}"

# Install Node.js via pnpm
echo ""
echo "Installing Node.js LTS via pnpm..."
pnpm env use --global lts

echo ""
echo "=== Package Installation Complete ==="
