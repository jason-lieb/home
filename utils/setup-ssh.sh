#!/usr/bin/env bash

echo "Setting up ssh key..."
cd ~
mkdir .ssh
yes '' | ssh-keygen -t ed25519 -C "jason.lieb@outlook.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

session_type=$(echo $XDG_SESSION_TYPE)

if [ "$session_type" == "wayland" ]; then
    cat ~/.ssh/id_ed25519.pub | wl-copy
    echo "Generated ssh key and copied to clipboard"
elif [ "$session_type" == "x11" ]; then
    cat ~/.ssh/id_ed25519.pub | xclip
    echo "Generated ssh key and copied to clipboard"
else
    echo "SSH Key:"
    cat ~/.ssh/id_ed25519.pub
fi
