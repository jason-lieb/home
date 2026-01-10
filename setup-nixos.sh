#!/usr/bin/env bash

set -e

printf "\nWhat is your email address?"
read -r email_address
printf "\nWhat is the hostname of this computer? "
read -r hostname

printf "\nSetting up ssh key..."
mkdir -p "$HOME/.ssh"
ssh-keygen -t ed25519 -C "$email_address" -N "" -f "$HOME/.ssh/id_ed25519"
eval "$(ssh-agent -s)" &> /dev/null
ssh-add "$HOME/.ssh/id_ed25519"

printf "\nCreating github cli shell and adding SSH key to GitHub...\n"
nix-shell -p gh --run "gh auth login -p ssh -w"
printf "\nCloning home repo...\n"
nix-shell -p git --run "git clone git@github.com:jason-lieb/home.git"

HOST_DIR="$HOME/home/nixos/$hostname"
mkdir -p "$HOST_DIR"
sudo cp /etc/nixos/hardware-configuration.nix "$HOST_DIR/hardware.nix"
sed -i "/nixosConfigurations = {/a\\        $hostname = mkNixos \"$hostname\";" "$HOME/home/flake.nix"
cat > "$HOST_DIR/default.nix" << EOF
{ ... }:

{
  networking.hostName = "$hostname";
  imports = [ ./hardware.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
EOF

printf "Setup .env file and then run the following command (including the ending \" )\n"
printf 'nix-shell -p git --run "sudo nixos-rebuild boot --impure --flake /home/jason/home#%s"' "$hostname"
