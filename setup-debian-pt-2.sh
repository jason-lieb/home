#!/usr/bin/env bash

set -e

printf "\nCreating github cli shell and adding SSH key to GitHub...\n"
nix-shell -p gh --run "gh auth login -p ssh -w"
printf "\nCloning home repo...\n"
nix-shell -p git --run "git clone git@github.com:jason-lieb/home.git"
cp /home/jason/home/.env.example /home/jason/home/.env

printf "\nInstalling home-manager...\n"
nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
printf "\nHome-manager installed successfully.\n"

printf "Setting up nix configuration...\n"
nix-shell -p git --run "home-manager switch --impure --flake /home/jason/home#jason@debian --extra-experimental-features 'nix-command flakes'"
