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

# Install dependencies
sudo dnf install unzip -y
sudo dnf install librdkafka-devel -y
sudo dnf install make -y
sudo dnf install ncurses-devel -y
sudo dnf install postgresql-devel -y
sudo dnf install pcre pcre-devel -y
sudo dnf install ncurses-compat-libs -y
sudo dnf install build-essential -y
sudo dnf install zlib1g-dev -y
sudo dnf install libghc-pcre-light-dev -y
sudo dnf install libpq-dev -y

# Install docker
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli [containerd.io](http://containerd.io/) docker-buildx-plugin docker-compose-plugin
sudo systemctl enable docker
sudo adduser "$USER" docker

# Install aws-cli
cd ~
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
export AWS_PROFILE=freckle-dev

# Create blank file for aws credentials
touch ~/.aws/credentials

# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Set default npm version
nvm alias default 16.20.0

# Increase inotify watchers
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p

# Install hls / other haskell tools
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

# Fix certificate errors
sudo cp ~/megarepo/ops/nginx-localhost-cert/wildcard.localhost.com.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust

# Allow pass through firewall
sudo firewall-cmd --add-port=3000/tcp --permanent
sudo firewall-cmd --reload
sudo firewall-cmd --zone=public --add-interface=cscotun0 --permanent
sudo firewall-cmd --zone=public --add-interface=cscotun0
sudo firewall-cmd --reload

# Install stack?
# curl -sSL https://get.haskellstack.org/ | sh

# Nix determinate installer (source: https://github.com/DeterminateSystems/nix-installer)
# curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Set up VPN
# sudo dnf copr enable yuezk/globalprotect-openconnect -y
# sudo dnf install globalprotect-openconnect -y

# Add hosts to /etc/hosts
# sudo bash -c 'echo -e "\
# 127.0.0.1 localhost.com\n\
# 127.0.0.1 api.localhost.com\n\
# 127.0.0.1 assets.localhost.com\n\
# 127.0.0.1 classroom.localhost.com\n\
# 127.0.0.1 school.localhost.com\n\
# 127.0.0.1 student.localhost.com\n\
# 127.0.0.1 console.localhost.com\n\
# 127.0.0.1 faktory.localhost.com\n\
# 127.0.0.1 tts.localhost.com\n\
# 127.0.0.1 sso.localhost.com" >> /etc/hosts'

# Add aws config to ~/.aws/config
# [profile freckle]
# sso_start_url = https://d-90675613ab.awsapps.com/start
# sso_region = us-east-1
# sso_account_id = 853032795538
# sso_role_name = Freckle-Prod-Engineers
# region = us-east-1

# [profile freckle-dev]
# sso_start_url = https://d-90675613ab.awsapps.com/start
# sso_region = us-east-1
# sso_account_id = 539282909833
# sso_role_name = Freckle-Dev-Engineers
# region = us-east-1
