#!/bin/bash

yes | ssh-keygen -t ed25519 -C “jason.lieb@outlook.com”
# [Enter x3] -> shouldn't be necessary because of the `yes |`
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy to clipboard if using X11
cat ~/.ssh/id_ed25519.pub | xclip

# Copy to clipboard if using Wayland
# cat ~/.ssh/id_ed25519.pub | ???