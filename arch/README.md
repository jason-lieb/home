# Arch Linux Setup

Complete Arch Linux installation and configuration system that mirrors an existing NixOS desktop setup.

## Overview

This repository provides a two-phase approach to setting up Arch Linux:

1. **Phase 1:** Use `archinstall` with the provided JSON configuration for base system installation
2. **Phase 2:** Run modular bash scripts for post-install configuration

Each module is idempotent and can run independently.

## Prerequisites

- Arch Linux live USB
- Internet connection (wired or wireless)
- Target disk for installation

## Phase 1: Base Installation

1. Boot from Arch Linux live USB
2. Connect to the internet:
   ```bash
   # For WiFi:
   iwctl
   station wlan0 connect YOUR_SSID

   # Verify connection:
   ping archlinux.org
   ```
3. Copy the configuration to the live environment:
   ```bash
   # From another machine or USB:
   curl -fO https://raw.githubusercontent.com/jason-lieb/home/main/arch/archinstall.json
   ```
4. Prepare the disk (see [Dual-Boot Notes](#dual-boot-notes-nixoswindows) if dual-booting)
5. Run archinstall with the configuration:
   ```bash
   archinstall --config archinstall.json
   ```
6. Follow prompts to set user password
7. Reboot into the new system

### Dual-Boot Notes (NixOS/Windows)

If installing alongside an existing NixOS + Windows dual-boot, prepare the disk
yourself so archinstall never touches your other partitions.

#### 1. Partition and mount before archinstall

```bash
# Open cfdisk to see all partitions and free space, then create the Arch partition
cfdisk /dev/<your-disk>
# Select the free space → New → accept the size → Write → Quit

# Format as btrfs
mkfs.btrfs /dev/<your-new-partition>

# Create subvolumes
mount /dev/<your-new-partition> /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
umount /mnt

# Mount subvolumes where archinstall expects
mkdir -p /mnt/archinstall
mount -o subvol=@,compress=zstd,noatime /dev/<your-new-partition> /mnt/archinstall
mkdir -p /mnt/archinstall/{home,.snapshots,boot}
mount -o subvol=@home,compress=zstd,noatime /dev/<your-new-partition> /mnt/archinstall/home
mount -o subvol=@snapshots,compress=zstd,noatime /dev/<your-new-partition> /mnt/archinstall/.snapshots

# Mount your existing ESP without formatting
mount /dev/<your-esp-partition> /mnt/archinstall/boot
```

Since `archinstall.json` has no `disk_config`, archinstall will use
whatever is mounted at `/mnt/archinstall` without performing any disk operations.

#### 2. Run archinstall

```bash
archinstall --config archinstall.json
```

Skip the bootloader prompt — your existing systemd-boot (from NixOS) will
manage all boot entries.

## Phase 2: Post-Install Configuration

1. Clone this repository:
   ```bash
   git clone https://github.com/jason-lieb/home.git
   cd home/arch
   ```
2. Run the install script:
   ```bash
   ./install --user jason --host desktop
   ```
3. Re-run safely at any time (idempotent):
   ```bash
   ./install --from 02-dotfiles.sh --to 06-session-defaults.sh
   ```
4. Reboot to apply all changes

### Dotfiles Model (Hybrid)

- `modules/02-dotfiles.sh` links repository-managed files from `dotfiles/` (at the repo root) into `$HOME`
- Arch/KDE/system behavior remains script-generated in `modules/03-services.sh`, `modules/04-plasma.sh`, and `modules/06-session-defaults.sh`
- Existing local files are backed up as `<path>.backup` before replacement

## Module Descriptions

| Module | Description |
|--------|-------------|
| `01-packages.sh` | Installs yay (AUR helper) and all packages from official repos and AUR |
| `02-dotfiles.sh` | Symlinks dotfiles, installs VS Code extensions, generates SSH key, sets fish as default shell |
| `03-services.sh` | Enables systemd services (docker, syncthing, bluetooth), configures firewall |
| `04-plasma.sh` | Sets up KDE Plasma theme, shortcuts, virtual desktops, window rules |
| `05-gaming.sh` | Configures emulators (Dolphin, PrimeHack, AM2R), gaming peripherals |
| `06-session-defaults.sh` | Applies host-based MIME defaults and autostart behavior (`mini` vs others) |

## Directory Structure

```
home/                           # Repository root
├── dotfiles/                   # Repo-managed dotfiles linked into $HOME
│   ├── .bashrc
│   ├── .zshrc
│   ├── .gitconfig
│   ├── .gitignore
│   ├── .aws/config
│   ├── .claude/settings.json
│   ├── .ssh/config
│   ├── vscode/
│   │   ├── settings.json
│   │   ├── extensions.txt
│   │   └── snippets/
│   │       └── typescript.json
│   └── .config/
│       ├── direnv/direnvrc
│       ├── fish/config.fish
│       ├── gh/config.yml
│       └── ghostty/config
└── arch/
    ├── install                 # Main orchestrator script
    ├── archinstall.json # archinstall preset
    └── modules/
        ├── 01-packages.sh
        ├── 02-dotfiles.sh
        ├── 03-services.sh
        ├── 04-plasma.sh
        ├── 05-gaming.sh
        └── 06-session-defaults.sh
```

## Nix (Optional, Dev Tooling Only)

If you still want Nix for project shells/flakes (but not system or dotfile management), install it after base setup:

```bash
# Recommended installer
curl -fsSL https://install.determinate.systems/nix | sh -s -- install

# Then verify
nix --version
nix flake --help
```

Keep Nix scoped to project workflows (`nix develop`, `nix run`) and continue using these scripts/systemd/pacman for OS configuration.

## Testing Checklist

After running the setup, verify each component:

### Package Installation
```bash
# Verify yay is installed
which yay

# Verify official packages
pacman -Q fish bat htop

# Verify AUR packages
pacman -Q ghostty obsidian
```

### Dotfiles
```bash
# Verify expected symlinks point to this repo
readlink ~/.bashrc
readlink ~/.config/fish/config.fish
readlink ~/.config/ghostty/config

# Open new fish shell and verify custom prompt
fish

# Test alias
type gs  # Should show 'git stash'

# Verify git config
git config user.name

# Verify ghostty config
cat ~/.config/ghostty/config

# Verify zoxide
z --help
```

### Services
```bash
# Verify systemd services
systemctl status docker
systemctl --user status syncthing
systemctl status bluetooth

# Verify firewall
sudo ufw status

# Verify hosts file
grep localhost.com /etc/hosts
```

### KDE Plasma
- Log out and log back in
- Verify Breeze Dark theme is applied
- Test Meta key opens KRunner
- Test Ctrl+Alt+Right switches virtual desktop
- Test Ctrl+Alt+Shift+Right moves window without switching

### Gaming
```bash
# Verify Steam launches
steam &

# Verify Dolphin
dolphin-emu &

# Verify PrimeHack wrapper
primehack --help

# Verify GCC adapter module
lsmod | grep gcadapter

# Verify AM2R
flatpak run io.github.am2r_community_developers.AM2RLauncher &
```

## Troubleshooting

### yay Installation Fails

If yay fails to install:
```bash
# Ensure base-devel is installed
sudo pacman -S --needed base-devel git

# Try manual installation
cd /tmp
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si
```

### Service Enable Fails

If a service fails to enable:
```bash
# Check if the package is installed
pacman -Q docker syncthing

# Check service status
systemctl status <service-name>

# View logs
journalctl -u <service-name> -b
```

### KDE Config Not Applying

KDE config changes require logging out and back in. If changes still don't apply:
```bash
# Reload KWin
qdbus org.kde.KWin /KWin reconfigure

# Or restart Plasma
kquitapp5 plasmashell && kstart5 plasmashell
```

### Firewall Blocking Services

If services are being blocked:
```bash
# Check UFW status
sudo ufw status verbose

# Disable temporarily for testing
sudo ufw disable

# Re-enable after testing
sudo ufw enable
```

### Docker Permission Denied

If docker commands fail with permission denied:
```bash
# Add user to docker group (then logout/login)
sudo usermod -aG docker $USER

# Or use sudo
sudo docker ps
```

### Syncthing Not Accessible

If Syncthing web UI isn't accessible:
```bash
# Check if service is running
systemctl status syncthing@jason

# Check port
ss -tlnp | grep 8384

# Access web UI
xdg-open http://localhost:8384
```

### GCC Adapter Not Detected

If GameCube controller adapter isn't working:
```bash
# Check USB devices
lsusb | grep -i nintendo

# Check udev rules
ls /etc/udev/rules.d/51-dolphin*

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Check kernel module
lsmod | grep gcadapter
```

### Fish Shell Not Default

To set fish as default shell:
```bash
# Verify fish is in /etc/shells
cat /etc/shells | grep fish

# If not, add it
echo /usr/bin/fish | sudo tee -a /etc/shells

# Set as default
chsh -s /usr/bin/fish
```
