#!/usr/bin/env bash

set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

cd ~

printf "\nSetting up ssh key..."
printf "\nWhat is your email address? "
read email_address
yes '' | ssh-keygen -t ed25519 -C $email_address &> /dev/null
eval "$(ssh-agent -s)" &> /dev/null
ssh-add ~/.ssh/id_ed25519

printf "\nSetting up ssh key with Github...\n"
read -p "What is the name of the ssh key? " ssh_key_name

printf "\nCreating github cli shell and adding SSH key to GitHub..."
nix-shell -p gh --run "gh auth login; gh ssh-key add ~/.ssh/id_ed25519.pub -t '$ssh_key_name'"

printf "\n"
nix-shell -p git --run "git clone git@github.com:jason-lieb/home-nix.git"

printf "\nWhat is the hostname of this computer? "
read hostname
sudo hostname $hostname
sudo cp /etc/nixos/hardware-configuration.nix ~/home-nix/$hostname/hardware-configuration.nix

echo "Setting up nix configuration..."
sudo nixos-rebuild switch --flake ~/home-nix#$hostname
