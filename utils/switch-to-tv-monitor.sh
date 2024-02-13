#!/usr/bin/env bash

echo "Switching to TV monitor"
rm ~/.config/monitors.xml
ln -sf ~/home/dotfiles/tv-monitor.xml ~/.config/monitors.xml
systemctl restart gdm
