#!/usr/bin/env bash

# Clone home directory
cd ~
git clone git@github.com:jason-lieb/home.git

# Give scripts executable permissions
chmod +x ./utils/setup-dotfiles.sh
chmod +x ./utils/setup-vscode-extensions.sh
# chmod +x ./utils/setup-fedora-vm.sh

# Run scripts to finish setup
. ~/home/utils/setup-dotfiles.sh
. ~/home/utils/setup-vscode-extensions.sh