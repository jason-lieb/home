#!/usr/bin/env bash

set -e

cd $HOME
mkdir -p ~/.ssh

printf "\nSetting up ssh key..."
printf "\nWhat is your email address? (Note: After this, you are going to have to enter your password 3 times)"
read email_address
yes '' | ssh-keygen -t ed25519 -C $email_address &> /dev/null
eval "$(ssh-agent -s)" &> /dev/null
ssh-add $HOME/.ssh/id_ed25519

printf "Installing Nix..."
sh <(curl -L https://nixos.org/nix/install) --daemon

# printf "\nCreating github cli shell and adding SSH key to GitHub...\n"
# nix-shell -p gh --run "gh auth login -p ssh -w"
# printf "\n"
# nix-shell -p git --run "git clone git@github.com:jason-lieb/home-nix.git"

# printf "\nWhat is the hostname of this computer? "
# read hostname
# sudo hostname $hostname
# mkdir -p $HOME/home-nix/$hostname
# sudo cp /etc/nixos/hardware-configuration.nix $HOME/home-nix/$hostname/hardware-configuration.nix

# printf "Setting up nix configuration...\n"
# nix-shell -p git --run "sudo nixos-rebuild switch --flake $HOME/home-nix#$hostname --impure"
