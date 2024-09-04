#!/usr/bin/env bash

set -e

if ! sudo -l &>/dev/null; then
    su -
    usermod -aG sudo jason
    exit
fi

cd $HOME
mkdir -p ~/.ssh

printf "\nSetting up ssh key..."
printf "\nWhat is your email address?\n"
read email_address
yes '' | ssh-keygen -t ed25519 -C $email_address &> /dev/null
eval "$(ssh-agent -s)" &> /dev/null
ssh-add $HOME/.ssh/id_ed25519

printf "Installing Nix..."
sh <(curl -L https://nixos.org/nix/install) --daemon

printf "\nNix Installation Complete\n"
printf "\nRestart the shell before running part 2 of the script\n"
