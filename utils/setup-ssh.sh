#!/bin/bash

yes | ssh-keygen -t ed25519 -C "jason.lieb@outlook.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

session_type=$(echo $XDG_SESSION_TYPE)

if [ "$session_type" == "wayland" ]; then
    # Copy to clipboard if using Wayland
    # cat ~/.ssh/id_ed25519.pub | ???

    # Output ssh key to terminal
    cat ~/.ssh/id_ed25519.pub
elif [ "$session_type" == "x11" ]; then
    # Copy to clipboard if using X11
    cat ~/.ssh/id_ed25519.pub | xclip
else
    # Output ssh key to terminal
    cat ~/.ssh/id_ed25519.pub
fi
