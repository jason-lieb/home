#!/bin/bash

# Delete files if they already exist
rm ~/.bashrc
rm ~/.gitconfig
rm ~/.config/Code/User/settings.json

# Create symlink and force overwrite
ln -sf ~/home/dotfiles/.bashrc ~/.bashrc
ln -sf ~/home/dotfiles/.gitconfig ~/.gitconfig
ln -sf ~/home/dotfiles/vscode-settings.json ~/.config/Code/User/settings.json

echo "Dotfiles updated."
