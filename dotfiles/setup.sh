#!/bin/bash

git clone https://github.com/jason-lieb/.dotfiles.git ~/.dotfiles

# Options for placing dotfiles in home directory
# 1. Symlink: ln -sf ~/.dotfiles/.bashrc ~/.bashrc
# 2. Copy Files: cp ~/.dotfiles/.bashrc ~/.bashrc

ln -sf ~/.dotfiles/.bashrc ~/.bashrc
ln -sf ~/.dotfiles/.gitconfig ~/.gitconfig

echo "Dotfiles setup complete."
