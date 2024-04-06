#!/usr/bin/env bash

set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

echo "Setting up ssh key..."
cd ~
mkdir -p .ssh
sleep 3

read -p "What is your email address?" email_address
yes '' | ssh-keygen -t ed25519 -C $email_address
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
sleep 3

echo "Setting up ssh key with Github..."
read -p "What is the name of the ssh key?" ssh_key_name
sleep 3

echo "Creating github cli shell and adding SSH key to GitHub..."
nix-shell -p gh --run "gh auth login; gh ssh-key add ~/.ssh/id_ed25519.pub -t $ssh_key_name"
sleep 3

echo "Cloning nix configuration..."
git clone git@github.com:jason-lieb/home-nix.git
sleep 3

read -p "What is the hostname of this computer?" hostname
sudo hostnamectl set-hostname $hostname
sudo cp /etc/nixos/hardware-configuration.nix ./home-nix/$hostname/hardware-configuration.nix
sleep 3

echo "Setting up nix configuration..."
sudo nixos-rebuild switch --flake ./home-nix#$hostname
