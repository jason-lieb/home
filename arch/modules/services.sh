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

sudo install -d -m 0755 -o "$TARGET_USER" -g "$TARGET_USER" "$TARGET_HOME/.config/environment.d"
cat > "$TARGET_HOME/.config/environment.d/10-local.conf" << EOF
NPM_CONFIG_PREFIX=${TARGET_HOME}/.npm-packages
PATH=${TARGET_HOME}/.npm-packages/bin:${TARGET_HOME}/.local/bin:%h/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EOF
sudo chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/environment.d/10-local.conf"

# Set fish as default shell for parity with Nix user config
if command -v fish >/dev/null 2>&1; then
    fish_bin="$(command -v fish)"
    if ! getent shells | grep -q "$fish_bin"; then
        echo "$fish_bin" | sudo tee -a /etc/shells > /dev/null
    fi
    sudo chsh -s "$fish_bin" "$TARGET_USER" || true
fi

# Start ssh-agent at user login/session startup
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
echo "Creating bluetooth power-on service..."

sudo tee /etc/systemd/system/bluetooth-power-on.service > /dev/null << 'BTSERVICE'
[Unit]
Description=Power on bluetooth adapter
After=bluetooth.service
Wants=bluetooth.service

[Service]
Type=oneshot
RemainAfterExit=no
ExecStart=/bin/bash -lc 'for _ in {1..30}; do bluetoothctl show >/dev/null 2>&1 && break; sleep 2; done; bluetoothctl power on'

[Install]
WantedBy=multi-user.target
BTSERVICE

sudo systemctl daemon-reload
sudo systemctl enable bluetooth-power-on.service

# ============================================
# Firewall Configuration
# ============================================
echo "Configuring firewall..."

# Enable UFW if not already
if ! sudo ufw status | grep -q "Status: active"; then
    sudo ufw --force enable
fi

# Open ports (idempotent - ufw handles duplicates)
sudo ufw allow 3000/tcp comment 'Dev server'
sudo ufw allow 5432/tcp comment 'PostgreSQL'
sudo ufw allow 5434/tcp comment 'PostgreSQL alt'
sudo ufw allow 19000/tcp comment 'Expo'
sudo ufw allow 19001/tcp comment 'Expo'

echo "Firewall rules configured"

# ============================================
# /etc/hosts Configuration
# ============================================
echo "Configuring /etc/hosts..."

HOSTS_BLOCK_START="# >>> arch-setup managed localhost aliases >>>"
HOSTS_BLOCK_END="# <<< arch-setup managed localhost aliases <<<"
HOSTS_MANAGED_BLOCK="$(cat <<'EOF'
# >>> arch-setup managed localhost aliases >>>
127.0.0.1 localhost.com
# <<< arch-setup managed localhost aliases <<<
EOF
)"

tmp_hosts="$(mktemp)"
awk -v start="$HOSTS_BLOCK_START" -v end="$HOSTS_BLOCK_END" '
  $0 == start { in_block=1; next }
  $0 == end { in_block=0; next }
  !in_block { print }
' /etc/hosts > "$tmp_hosts"
printf "%s\n" "$HOSTS_MANAGED_BLOCK" >> "$tmp_hosts"

if ! cmp -s "$tmp_hosts" /etc/hosts; then
    sudo install -m 0644 "$tmp_hosts" /etc/hosts
    echo "Updated /etc/hosts managed aliases block"
else
    echo "/etc/hosts already up to date"
fi
rm -f "$tmp_hosts"

# Keep passwordless sudo parity with existing Nix setup.
if getent group wheel >/dev/null; then
    echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/99-wheel-nopasswd > /dev/null
elif getent group sudo >/dev/null; then
    echo '%sudo ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/99-sudo-nopasswd > /dev/null
fi
sudo chmod 0440 /etc/sudoers.d/99-wheel-nopasswd /etc/sudoers.d/99-sudo-nopasswd 2>/dev/null || true

echo ""
echo "=== Services Configuration Complete ==="
