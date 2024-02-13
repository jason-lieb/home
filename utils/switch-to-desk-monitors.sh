#!/usr/bin/env bash

echo "Switching to desk monitors"
rm ~/.config/monitors.xml
ln -sf ~/home/dotfiles/desk-monitors.xml ~/.config/monitors.xml
systemctl restart gdm
