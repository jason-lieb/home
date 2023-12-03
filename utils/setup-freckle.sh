#!/usr/bin/env bash

sudo locale-gen 'en_US.UTF-8'
sudo update-locale LANG='en_US.UTF-8'
sudo update-locale LC_ALL='en_US.UTF-8'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Check if ufw is running
sudo service ufw status

sudo ufw allow 3000
sudo ufw allow in on cscotun0
sudo ufw allow out on cscotun0

echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p

sudo dnf -y install build-essential zlib1g-dev libghc-pcre-light-dev libpq-dev

sudo adduser "$USER" docker