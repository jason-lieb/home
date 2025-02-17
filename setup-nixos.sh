#!/usr/bin/env bash

set -e

cd $HOME
mkdir -p ~/.ssh

printf "\nSetting up ssh key..."
printf "\nWhat is your email address?\n(Note: After this, you are going to have to enter your password 3 times)\n"
read email_address
yes '' | ssh-keygen -t ed25519 -C $email_address &> /dev/null
eval "$(ssh-agent -s)" &> /dev/null
ssh-add $HOME/.ssh/id_ed25519

printf "\nCreating github cli shell and adding SSH key to GitHub...\n"
nix-shell -p gh --run "gh auth login -p ssh -w"
printf "\nCloning home repo...\n"
nix-shell -p git --run "git clone git@github.com:jason-lieb/home.git"

printf "\nWhat is the hostname of this computer? "
read hostname
sudo hostname $hostname
mkdir -p $HOME/home/nixos/$hostname
sudo cp /etc/nixos/hardware-configuration.nix $HOME/home/nixos/$hostname/hardware.nix

printf "Setup .env file and then run the following command (including the ending \" )\n"
printf 'nix-shell -p git --run "sudo nixos-rebuild boot --impure --flake /home/jason/home#{hostname}"\n'
printf "where {hostname} is "
printf $hostname
