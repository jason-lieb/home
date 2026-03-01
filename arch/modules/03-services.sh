#!/bin/bash
set -euo pipefail

TARGET_USER="jason"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
SYNCTHING_HOME="${TARGET_HOME}/.local/share/syncthing/.config/syncthing"

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

# Keep Syncthing running for user sessions even when logged out
sudo loginctl enable-linger "$TARGET_USER" || true

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
# Syncthing Configuration
# ============================================
echo "Configuring syncthing..."

# Create sync directories
echo "Creating sync directories..."
mkdir -p "$TARGET_HOME/.local/share/syncthing"
mkdir -p "$TARGET_HOME/.local/share/dolphin-emu/GC"
mkdir -p "$TARGET_HOME/.local/share/dolphin-emu/Wii"
mkdir -p "$TARGET_HOME/.config/dolphin-emu/Profiles"
mkdir -p "$TARGET_HOME/Documents/dolphin"
mkdir -p "$TARGET_HOME/Documents/mgba"
mkdir -p "$TARGET_HOME/Documents/am2r"
mkdir -p "$TARGET_HOME/Documents/snes"
mkdir -p "$TARGET_HOME/.local/share/primehack/GC"
mkdir -p "$TARGET_HOME/.local/share/primehack/Wii"
mkdir -p "$TARGET_HOME/.local/share/primehack/Config/Profiles"
sudo chown -R "${TARGET_USER}:${TARGET_USER}" "$TARGET_HOME/.local/share/syncthing" "$TARGET_HOME/Documents" "$TARGET_HOME/.config/dolphin-emu" "$TARGET_HOME/.local/share/primehack" "$TARGET_HOME/.local/share/dolphin-emu"

# Use user-level syncthing with the same data/config layout as Nix.
sudo systemctl disable --now "syncthing@${TARGET_USER}" 2>/dev/null || true
mkdir -p "$TARGET_HOME/.config/systemd/user/syncthing.service.d"
cat > "$TARGET_HOME/.config/systemd/user/syncthing.service.d/override.conf" << EOF
[Service]
ExecStart=
ExecStart=/usr/bin/syncthing serve --no-browser --no-restart --home=${SYNCTHING_HOME}
EOF
sudo chown -R "${TARGET_USER}:${TARGET_USER}" "$TARGET_HOME/.config/systemd/user/syncthing.service.d"
sudo -u "$TARGET_USER" systemctl --user daemon-reload || true

if command -v syncthing >/dev/null 2>&1; then
    sudo -u "$TARGET_USER" mkdir -p "$SYNCTHING_HOME"
    sudo -u "$TARGET_USER" syncthing generate --home="$SYNCTHING_HOME" >/dev/null 2>&1 || true

    if command -v python3 >/dev/null 2>&1; then
        sudo -u "$TARGET_USER" python3 - "$SYNCTHING_HOME/config.xml" "$TARGET_HOME" <<'PY'
import sys
import xml.etree.ElementTree as ET

config_path = sys.argv[1]
home = sys.argv[2]

tree = ET.parse(config_path)
root = tree.getroot()

known_devices = {
    "desktop": "6VW6XO3-4NY4ING-SUYWZIO-ULIVMZ7-ROFUS2F-6ZJE6ZX-X4KXIYY-Z6I43QC",
    "laptop": "E44XEWP-DHRVVXR-3WSATAY-XL2G6L6-XAQIXEI-VPNNDPM-66CZKN3-ALG3XQA",
    "mini": "ZGTQSNB-CS4454Y-THQKHL3-FNZWSLT-62GC7PG-SR6C4W4-AUFD3P2-3D2AFAA",
}

for name, did in known_devices.items():
    existing = next((d for d in root.findall("device") if d.get("id") == did), None)
    if existing is None:
        ET.SubElement(
            root,
            "device",
            {"id": did, "name": name, "compression": "metadata", "introducer": "false"},
        )
    else:
        existing.set("name", name)
        if not existing.get("compression"):
            existing.set("compression", "metadata")
        if not existing.get("introducer"):
            existing.set("introducer", "false")

local_device = next((d for d in root.findall("device") if d.get("id") not in known_devices.values()), None)
local_id = local_device.get("id") if local_device is not None else None

folder_specs = [
    ("dolphin-gc", f"{home}/.local/share/dolphin-emu/GC"),
    ("dolphin-wii", f"{home}/.local/share/dolphin-emu/Wii"),
    ("dolphin-profiles", f"{home}/.config/dolphin-emu/Profiles"),
    ("dolphin-roms", f"{home}/Documents/dolphin"),
    ("mgba-roms", f"{home}/Documents/mgba"),
    ("primehack-gc", f"{home}/.local/share/primehack/GC"),
    ("primehack-wii", f"{home}/.local/share/primehack/Wii"),
    ("primehack-profiles", f"{home}/.local/share/primehack/Config/Profiles"),
    ("am2r", f"{home}/Documents/am2r"),
    ("snes", f"{home}/Documents/snes"),
]

default_folder = next((f for f in root.findall("folder") if f.get("id") == "default"), None)
if default_folder is not None:
    root.remove(default_folder)

shared_device_ids = list(known_devices.values())
if local_id and local_id not in shared_device_ids:
    shared_device_ids.append(local_id)

for folder_id, folder_path in folder_specs:
    folder = next((f for f in root.findall("folder") if f.get("id") == folder_id), None)
    attrs = {
        "id": folder_id,
        "label": folder_id,
        "path": folder_path,
        "type": "sendreceive",
        "rescanIntervalS": "3600",
        "fsWatcherEnabled": "true",
        "fsWatcherDelayS": "10",
    }
    if folder is None:
        folder = ET.SubElement(root, "folder", attrs)
    else:
        for k, v in attrs.items():
            folder.set(k, v)

    for dev in list(folder.findall("device")):
        folder.remove(dev)
    for did in shared_device_ids:
        ET.SubElement(folder, "device", {"id": did})

tree.write(config_path, encoding="utf-8", xml_declaration=True)
PY
    fi
fi

sudo -u "$TARGET_USER" systemctl --user enable --now syncthing || true

cat << 'SYNCINFO'
Syncthing device IDs for reference:
- desktop: 6VW6XO3-4NY4ING-SUYWZIO-ULIVMZ7-ROFUS2F-6ZJE6ZX-X4KXIYY-Z6I43QC
- laptop:  E44XEWP-DHRVVXR-3WSATAY-XL2G6L6-XAQIXEI-VPNNDPM-66CZKN3-ALG3XQA
- mini:    ZGTQSNB-CS4454Y-THQKHL3-FNZWSLT-62GC7PG-SR6C4W4-AUFD3P2-3D2AFAA

Configure sharing at: http://localhost:8384
SYNCINFO

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
sudo ufw allow 8384/tcp comment 'Syncthing web UI'
sudo ufw allow 19000/tcp comment 'Expo'
sudo ufw allow 19001/tcp comment 'Expo'
sudo ufw allow 22000/tcp comment 'Syncthing sync'
sudo ufw allow 22000/udp comment 'Syncthing sync'
sudo ufw allow 21027/udp comment 'Syncthing discovery'

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
printf "\n%s\n" "$HOSTS_MANAGED_BLOCK" >> "$tmp_hosts"

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
