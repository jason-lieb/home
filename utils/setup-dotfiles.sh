#!/usr/bin/env bash

# Delete files if they already exist
rm ~/.bashrc
rm ~/.config/fish/config.fish
rm ~/.gitconfig
rm ~/.config/Code/User/settings.json

# Create symlink and force overwrite
ln -sf ~/home/dotfiles/.bashrc ~/.bashrc
ln -sf ~/home/dotfiles/config.fish ~/.config/fish/config.fish
ln -sf ~/home/dotfiles/.gitconfig ~/.gitconfig
ln -sf ~/home/dotfiles/vscode-settings.json ~/.config/Code/User/settings.json

echo "Dotfiles updated."
