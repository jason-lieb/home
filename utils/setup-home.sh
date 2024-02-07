#!/usr/bin/env bash

# Clone home directory
cd ~
git clone git@github.com:jason-lieb/home.git

# Give scripts executable permissions
chmod +x ~/home/utils/setup-dotfiles.sh
chmod +x ~/home/utils/setup-vscode-extensions.sh
chmod +x ~/home/utils/switch-to-desk-monitors.sh
chmod +x ~/home/utils/switch-to-tv-monitor.sh
# chmod +x ~/home/utils/setup-fedora-vm.sh

# Run scripts to finish setup
. ~/home/utils/setup-dotfiles.sh
. ~/home/utils/setup-vscode-extensions.sh