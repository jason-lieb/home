# Arch Linux Setup

Complete Arch Linux installation and configuration system that mirrors an existing NixOS desktop setup.

## Overview

This repository provides a two-phase approach to setting up Arch Linux:

1. **Phase 1:** Use `archinstall` with the provided JSON configuration for base system installation
2. **Phase 2:** Run modular bash scripts for post-install configuration

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
   ./install        # Core modules only
   ./install --all  # Core + optional modules (syncthing, gaming)
   ```
3. Reboot to apply all changes

## Nix (Optional)

If you still want Nix, install it after base setup:

```bash
# Recommended installer
curl -fsSL https://install.determinate.systems/nix | sh -s -- install

