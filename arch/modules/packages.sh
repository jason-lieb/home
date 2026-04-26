#!/bin/bash
set -euo pipefail

GREEN='\033[1;32m'
NC='\033[0m'
msg() { echo -e "${GREEN}$*${NC}"; }

msg "=== Package Installation ==="

OFFICIAL_PACKAGES=(
    fish bash git base-devel openssh
    bat htop jq wget ffmpeg make lsof zoxide lazygit lf tokei just github-cli
    docker docker-compose flatpak usbutils ufw bluez bluez-utils
    pipewire-alsa pipewire-pulse wireplumber lib32-mesa
    plasma-meta sddm dolphin okular gwenview bluedevil kcalc krdc kdeconnect
    plasma-browser-integration ksshaskpass kcolorchooser filelight
    firefox vivaldi
    bun direnv
    aws-cli-v2 gparted
    opencode
)

AUR_PACKAGES=(
    brave-bin google-chrome ghostty obsidian github-desktop-bin
    visual-studio-code-bin vivaldi-ffmpeg-codecs wl-clipboard fnm-bin
    opencode-desktop-bin
)

# Install yay if not present
install_yay() {
    if command -v yay &> /dev/null; then
        msg "yay is already installed"
        return 0
    fi

    msg "Installing yay..."
    local temp_dir
    temp_dir=$(mktemp -d)
    cd "$temp_dir"

    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm

    cd /
    rm -rf "$temp_dir"
    msg "yay installed successfully"
}

install_package_group() {
    local label="$1"
    shift
    local packages=("$@")

    if [[ ${#packages[@]} -eq 0 ]]; then
        msg "No packages defined for ${label}"
        return 0
    fi

    msg "Installing ${#packages[@]} packages for ${label}..."
    yay -S --needed --noconfirm "${packages[@]}"
}

# Enable multilib repository
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    msg "Enabling multilib repository..."
    sudo sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf
fi

# Update system first
msg "Updating system packages..."
sudo pacman -Syu --noconfirm

# Install yay
install_yay

# Install official packages
msg ""
msg "Installing official repository packages..."
install_package_group "official repositories" "${OFFICIAL_PACKAGES[@]}"

# Install AUR packages
msg ""
msg "Installing AUR packages..."
install_package_group "AUR" "${AUR_PACKAGES[@]}"

# Install Node.js + pnpm (via corepack)
msg ""
if ! command -v node &>/dev/null; then
    msg "Installing Node.js LTS via fnm..."
    eval "$(fnm env --shell bash)"
    fnm install --lts --corepack-enabled
    fnm use lts-latest
else
    msg "Node.js already installed"
fi

msg ""
msg "=== Package Installation Complete ==="
