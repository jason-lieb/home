#!/usr/bin/env bash

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

echo "Optimizing dnf settings..."
echo -e "fastestmirror=True\n\
        max_parallel_downloads=10\n\
        defaultyes=True\n\
        keepcache=True" | sudo tee -a /etc/dnf/dnf.conf

echo "Updating..."
sudo dnf -y update

echo "Installing software..."
sudo dnf -y install @gnome-desktop
sudo dnf -y install git
sudo dnf -y install gh
sudo dnf -y install vim
sudo dnf -y install neovim
sudo dnf -y install helix
sudo dnf -y install nano
sudo dnf -y install firefox
sudo dnf -y install alacritty
sudo dnf -y install fish
sudo dnf -y install htop
sudo dnf -y install neofetch
sudo dnf -y install tar
sudo dnf -y install gnome-tweaks
sudo dnf -y install chromium
sudo dnf -y install timeshift
sudo dnf -y install gnome-extensions-app
sudo dnf -y install docker
sudo dnf -y install zoxide
# sudo dnf -y install xclip # Need wayland alternative
# sudo dnf -y install kdeconnectd
# sudo dnf -y install dnfdragora

echo "Installing Copilot Cli..."
gh extension install github/gh-copilot

echo "Installing bass for fish..."
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
fisher install edc/bass

echo "Setting up docker..."
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

echo "Enabling gnome..."
sudo systemctl enable gdm
sudo systemctl set-default graphical.target

echo "Setting hostname..."
sudo hostnamectl set-hostname fedora

# Still needed now that I'm installing steam by flatpak?
echo "Adding rpm fusion..."
sudo dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
echo "Adding rpm fusion pt 2..."
sudo dnf config-manager --enable fedora-cisco-openh264
echo "Adding rpm fusion pt 3..."
sudo dnf -y groupupdate core

# echo "Installing steam..."
# sudo flatpak install flathub com.valvesoftware.Steam

echo "Installing media drivers..."
sudo dnf -y groupupdate multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
echo "Installing media drivers pt 2..."
sudo dnf -y groupupdate sound-and-video

# echo "Installing nix package manager..."
# bash -c "$(curl -fsSL https://nixos.org/nix/install)" --no-daemon # Single user ### investigate if multi-user install is possible with secure boot
# . /home/jason/.nix-profile/etc/profile.d/nix.fish

# Install via from https://github.com/the-via/releases/releases

echo "Installing brave..."
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
sudo dnf -y install brave-browser

echo "Installing vs code..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
dnf check-update
sudo dnf -y install code

echo "Adding flathub to flatpak..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "Installing preload for faster application startup..."
sudo dnf copr enable elxreno/preload -y && sudo dnf -y install preload

echo "Enabling ssh..."
systemctl enable sshd

# Currently doesn't work
echo "Changing default shell to fish..."
chsh -s /usr/bin/fish

echo "Finishing up..."
sudo dnf -y update
sudo dnf -y autoremove
sudo dnf clean packages

echo "Install Completed Successfully."

#

# Ssh connection
# sudo systemctl start sshd # Start ssh server
# sudo systemctl enable sshd # Start ssh server on boot
