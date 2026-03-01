# Pre-Migration Preflight Plan (Arch/Ubuntu)

## Goal
Reduce migration risk by capturing backups, hardware details, and rollback options before replacing NixOS.

## Scope
Use this checklist for each host (`desktop`, `laptop`, `mini`, `z560`) before install day.

## 1) Backup and Recovery
- Backup critical directories:
  - `~/.config`
  - `~/.local/share`
  - `~/.ssh`
  - browser profiles
  - emulator saves/configs (`dolphin`, `primehack`, `mgba`, `retroarch` if used)
- Keep at least one offline/external backup copy.
- Verify backup integrity by opening a few files from backup media.
- Export and save current package/app notes and any manual tweaks.

## 2) Sync and Identity Readiness
- Confirm Syncthing is healthy before migration:
  - all folders show `Up to Date`
  - no unresolved conflicts
- Save a copy of Syncthing device IDs and folder path mappings.
- Confirm accounts/tokens that matter are recoverable:
  - GitHub CLI auth
  - SSH keys
  - browser/password manager sync

## 3) Hardware and Driver Inventory
- Capture machine inventory and save outputs per host:
  - `lsblk`
  - `lspci -nn`
  - `lsusb`
  - `ip a`
- Record CPU vendor (for microcode package), GPU model, Wi-Fi/Bluetooth chipset.
- Note any unusual peripherals (GameCube adapter, docks, external audio, etc.).

## 4) Disk and Boot Decisions
- Decide partitioning strategy:
  - separate `/home` or single root
  - encryption on/off
  - swapfile vs swap partition
- Decide bootloader per host:
  - systemd-boot vs GRUB
- Confirm firmware mode and Secure Boot status.

## 5) Distro-Specific Decisions
- Arch:
  - choose AUR helper (`yay`) and confirm install approach.
  - decide package sources for apps not in official repos.
  - decide Nix installer method (Determinate installer vs official script) for dev-only usage.
- Ubuntu:
  - decide vendor repos vs `.deb` vs Flatpak for apps like browser/Cursor/PrimeHack.
  - confirm required multiverse/extra repos for gaming stack.
  - decide Nix installer method (Determinate installer vs official script) for dev-only usage.

## 6) Installer and Rollback Readiness
- Build and verify bootable USB media.
- Test boot each target machine from installer USB before migration.
- Keep rollback path:
  - do not wipe working system until pilot host is validated.
- Keep your Nix repo and migration plan reachable offline.

## 7) Pilot Host Strategy
- Migrate the least critical host first (recommended: `mini`).
- Validate baseline after first boot:
  - networking, audio, bluetooth, docker, syncthing, KDE session
- Validate emulator flow:
  - controller detection
  - Dolphin/PrimeHack/mGBA/RetroArch behavior
  - Steam features you use
- Only roll out to remaining hosts after pilot is stable.

## 8) Final Go/No-Go Checklist
- Backups complete and verified.
- Syncthing status clean before cutover.
- Hardware inventory captured.
- Partition/boot decisions finalized.
- Installer media tested.
- Pilot host chosen and migration window scheduled.
- Nix usage policy decided: use Nix for project tooling only, not OS/dotfile management.

