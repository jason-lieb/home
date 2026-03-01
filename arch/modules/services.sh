#!/bin/bash
set -euo pipefail

TARGET_USER="jason"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

echo "=== Services Configuration ==="

# ============================================
# Systemd Services
# ============================================
echo "Enabling systemd services..."

# Display manager
sudo systemctl enable sddm

# Networking
sudo systemctl enable NetworkManager

# Bluetooth
sudo systemctl enable bluetooth

# Docker
sudo systemctl enable docker
sudo systemctl enable docker.socket

# Start services that aren't already running
for service in NetworkManager bluetooth docker; do
    if ! systemctl is-active --quiet "$service"; then
        sudo systemctl start "$service"
    fi
done

# ============================================
# Docker Configuration
# ============================================
echo "Configuring docker..."

# Add user to docker group
if ! groups "$TARGET_USER" | grep -q docker; then
    sudo usermod -aG docker "$TARGET_USER"
    echo "Added ${TARGET_USER} to docker group (logout/login required)"
fi

# ============================================
# User Session Environment
# ============================================
echo "Configuring user session environment..."

sudo install -d -m 0755 -o "$TARGET_USER" -g "$TARGET_USER" "$TARGET_HOME/.config/environment.d"
cat > "$TARGET_HOME/.config/environment.d/10-local.conf" << EOF
PATH=${TARGET_HOME}/.local/bin:%h/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
SSH_AUTH_SOCK=\${XDG_RUNTIME_DIR}/ssh-agent.socket
EOF
sudo chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/environment.d/10-local.conf"

# ============================================
# SSH Agent
# ============================================
echo "Configuring ssh-agent user service..."

mkdir -p "$TARGET_HOME/.config/systemd/user"
cat > "$TARGET_HOME/.config/systemd/user/ssh-agent.service" << 'SSHAGENT'
[Unit]
Description=SSH key agent

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStart=/usr/bin/ssh-agent -D -a $SSH_AUTH_SOCK

[Install]
WantedBy=default.target
SSHAGENT
sudo chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/systemd"
sudo -u "$TARGET_USER" systemctl --user daemon-reload || true
sudo -u "$TARGET_USER" systemctl --user enable --now ssh-agent.service || true

# ============================================
# Bluetooth Power-On Workaround
# ============================================
# echo "Creating bluetooth power-on service..."
#
# sudo tee /etc/systemd/system/bluetooth-power-on.service > /dev/null << 'BTSERVICE'
# [Unit]
# Description=Power on bluetooth adapter
# After=bluetooth.service
# Wants=bluetooth.service
#
# [Service]
# Type=oneshot
# RemainAfterExit=no
# ExecStart=/bin/bash -lc 'for _ in {1..30}; do bluetoothctl show >/dev/null 2>&1 && break; sleep 2; done; bluetoothctl power on'
#
# [Install]
# WantedBy=multi-user.target
# BTSERVICE
#
# sudo systemctl daemon-reload
# sudo systemctl enable bluetooth-power-on.service

# ============================================
# Firewall Configuration
# ============================================
echo "Configuring firewall..."

if ! sudo ufw status | grep -q "Status: active"; then
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw --force enable
fi

echo "Firewall enabled (default deny incoming)"

# ============================================
# Passwordless Sudo
# ============================================
echo "Configuring passwordless sudo..."

if getent group wheel >/dev/null; then
    echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/99-wheel-nopasswd > /dev/null
elif getent group sudo >/dev/null; then
    echo '%sudo ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/99-sudo-nopasswd > /dev/null
fi
sudo chmod 0440 /etc/sudoers.d/99-wheel-nopasswd /etc/sudoers.d/99-sudo-nopasswd 2>/dev/null || true

echo ""
echo "=== Services Configuration Complete ==="
