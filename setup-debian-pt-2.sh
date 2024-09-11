#!/usr/bin/env bash

set -e

printf "\nCreating github cli shell and adding SSH key to GitHub...\n"
nix-shell -p gh --run "gh auth login -p ssh -w"
printf "\nCloning home repo...\n"
nix-shell -p git --run "git clone git@github.com:jason-lieb/home.git"
cp /home/jason/home/.env.example /home/jason/home/.env

printf "\nSetting up nix configuration...\n"
nix-shell -p git home-manager --run "home-manager switch --impure --flake /home/jason/home#jason@debian --extra-experimental-features 'nix-command flakes'"

printf "\nSetting up fish shell...\n"
echo "/home/jason/.nix-profile/bin/fish" | sudo tee -a /etc/shells
chsh -s /home/jason/.nix-profile/bin/fish
