#!/usr/bin/env bash

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

# Improve dnf
echo -e "fastestmirror=True\nmax_parallel_downloads=10\ndefaultyes=True\nkeepcache=True" | sudo tee -a /etc/dnf/dnf.conf

# Update fedora
sudo dnf -y update

# Install software
sudo dnf -y install \
  @gnome-desktop \
  iwd \
  networkmanager \
  git \
  vim \
  neovim \
  nano \
  firefox \
  alacritty \
  fish \
  htop \
  neofetch \
  tar \
  gnome-tweaks \
  chromium \
  timeshift \
  gnome-extensions-app \
  steam
# xclip \ # Need wayland alternative
# kdeconnectd \
# dnfdragora \

# Boot to gnome
sudo systemctl enable gdm
sudo systemctl set-default graphical.target

sudo hostnamectl set-hostname fedora

# Add RPM Fusion
sudo dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf config-manager --enable fedora-cisco-openh264
sudo dnf groupupdate core

# Install media drivers
sudo dnf groupupdate multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf groupupdate sound-and-video

# Install nix
sh <(curl -L https://nixos.org/nix/install) --no-daemon # Single user ### investigate if multi-user install is possible with secure boot
. /home/jason/.nix-profile/etc/profile.d/nix.sh

# Install brave
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
sudo dnf -y install brave-browser

# Install vscode
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
dnf check-update
sudo dnf -y install code

# Add flathub to flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install preload for faster application startup
sudo dnf copr enable elxreno/preload -y && sudo dnf -y install preload

# Sets default shell to fish
chsh -s /usr/bin/fish

# Clean up
sudo dnf -y update
sudo dnf -y autoremove
sudo dnf clean packages

echo "Install Completed Successfully. Rebooting..."

reboot

#

# Install librewolf
# sudo dnf config-manager --add-repo https://rpm.librewolf.net/librewolf-repo.repo
# sudo dnf -y install librewolf

# Ssh connection
# sudo systemctl start sshd # Start ssh server
# sudo systemctl enable sshd # Start ssh server on boot