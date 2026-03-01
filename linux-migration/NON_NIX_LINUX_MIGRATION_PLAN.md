# Non-Nix Linux Migration Plan (Arch or Ubuntu)

## Goal
Recreate the parts of your setup that are harder to translate from NixOS/Home Manager: system services and policies, Flatpak behavior, Syncthing, Linux session defaults/autostart, KDE behavior, and emulator workflows.

## Companion Docs
- `PRE_MIGRATION_PREFLIGHT_PLAN.md` for pre-cutover backup/hardware/go-no-go checks.
- `ARCH_BTRFS_SNAPSHOT_PLAN.md` for Arch-specific stability, snapshot, and rollback operations.

## Source Configs Used
- `nixos/default.nix`
- `nixos/plasma.nix`
- `home/linux/default.nix`
- `home/linux/plasma.nix`
- `home/utils/window-rules.nix`
- Host overlays:
  - `nixos/desktop/default.nix` + `nixos/desktop/hardware.nix`
  - `nixos/laptop/default.nix` + `nixos/laptop/hardware.nix`
  - `nixos/mini/default.nix` + `nixos/mini/hardware.nix`
  - `nixos/z560/default.nix` + `nixos/z560/hardware.nix`

## 1) System-Level Parity (`nixos/default.nix`)

### Core services
- Enable display stack and login manager:
  - Plasma desktop
  - SDDM (Wayland session)
- Enable networking:
  - NetworkManager service
- Enable audio:
  - PipeWire + WirePlumber
  - ALSA and PulseAudio compatibility layers
- Enable SSH agent behavior at login/session startup.

### Bluetooth
- Install BlueZ and KDE bluetooth integration tooling.
- Enable `bluetooth.service`.
- Recreate your Nix custom behavior that powers on adapter after boot:
  - Add a oneshot systemd unit that runs after bluetooth is available.
  - Use `bluetoothctl power on` only after the adapter is present.

### Docker
- Install Docker engine.
- Add `jason` to `docker` group.
- Enable docker service.

### Firewall parity (important for Syncthing/dev)
Open exactly these ports:
- TCP: `3000`, `5432`, `5434`, `8384`, `19000`, `19001`, `22000`
- UDP: `22000`, `21027`

### Other system behavior
- Keep timezone: `America/New_York`.
- Keep locale: `en_US.UTF-8` and related LC variables.
- Keep host mapping: `127.0.0.1 localhost.com`.
- Keep Fish as default shell for `jason`.
- Preserve NPM prefix env behavior:
  - `NPM_CONFIG_PREFIX=/home/jason/.npm-packages`
  - prepend `~/.npm-packages/bin` to `PATH`

### Host-specific boot/hardware parity
- `desktop`, `laptop`, `mini`:
  - UEFI + systemd-boot
- `z560`:
  - GRUB on `/dev/sda`
- `mini`:
  - swapfile (8 GB)
- `z560`:
  - swap partition
- CPU microcode:
  - AMD hosts -> AMD microcode package
  - Intel hosts -> Intel microcode package

## 2) Flatpak Parity (`nixos/default.nix` + `home/linux/default.nix`)

### Required behavior
- Flatpak installed and working.
- Flathub remote added.
- App installed:
  - `io.github.am2r_community_developers.AM2RLauncher`
- Filesystem override preserved for AM2R:
  - grant read-only access to `/run/udev`

### Validation
- `flatpak remotes` shows Flathub.
- AM2R launches.
- Controller/device access behaves as expected with `/run/udev:ro` override.

## 3) Syncthing Parity (`nixos/default.nix`)

### Service model and paths
- Run Syncthing as user `jason` (preferred: `systemd --user`) to match home-path ownership.
- Keep data/config rooted at:
  - `~/.local/share/syncthing`

### Devices
Re-add these device IDs:
- `desktop`
- `laptop`
- `mini`

(Use IDs from your current `nixos/default.nix`.)

### Folders (must match paths exactly)
- `~/.local/share/dolphin-emu/GC`
- `~/.local/share/dolphin-emu/Wii`
- `~/.config/dolphin-emu/Profiles`
- `~/Documents/dolphin`
- `~/Documents/mgba`
- `~/.local/share/primehack/GC`
- `~/.local/share/primehack/Wii`
- `~/.local/share/primehack/Config/Profiles`
- `~/Documents/am2r`
- `~/Documents/snes`

### Network requirements
- Web UI: `8384/TCP`
- Sync: `22000/TCP` and `22000/UDP`
- Local discovery: `21027/UDP`

### Validation
- Every shared folder reaches `Up to Date`.
- No path errors or permission errors.
- Emulator/profile directories stay writable by your user.

## 4) Linux User Session Parity (`home/linux/default.nix`)

### MIME/default apps
Set defaults:
- `application/zip` -> Dolphin
- `application/pdf` -> Okular
- `image/jpeg`, `image/png` -> Gwenview
- Browser defaults:
  - `mini`: Brave
  - all others: Vivaldi
  - apply to `text/html`, `video/mp4`, `x-scheme-handler/http`, `x-scheme-handler/https`

### Autostart behavior
- `mini`:
  - autostart Brave
- non-`mini` hosts:
  - autostart Vivaldi
  - autostart Obsidian
  - autostart Cursor

### Cursor/VS Code settings bridge
- Preserve this behavior:
  - if VS Code `settings.json` / `keybindings.json` exist
  - and Cursor files are missing
  - create symlinks in Cursor config to VS Code files

## 5) KDE Parity (`home/linux/plasma.nix` + `window-rules.nix`)

### Global look/feel and workspace
- Breeze Dark look and color scheme.
- Cursor theme/size.
- Wallpaper.
- 4 virtual desktops in one row.
- Screen locker behavior:
  - autolock disabled
  - lock on resume enabled

### KWin rules and behavior
- Maximize specific app windows:
  - Vivaldi, Cursor, VS Code, Obsidian, GitHub Desktop
- Desktop-specific behavior (desktop host):
  - default window size (1600x1000)
  - move selected windows to sideways screen

### Panels and shortcuts
- Bottom floating autohide task panel with launcher set.
- Top autohide panel with tray and clock prefs.
- Preserve custom shortcuts including tiling/window desktop navigation.

### Custom KDE files
- Recreate desktop entries:
  - `restart.desktop`
  - `shutdown.desktop`
  - `primehack.desktop`
- Recreate KWin script:
  - `movewindownoswitch`
  - metadata + JS contents
  - ensure plugin is enabled

### Power profiles
- Laptop:
  - AC/battery/low-battery policies (dim, display off, suspend, power profile)
- Mini:
  - AC profile with no autosuspend
- Desktop:
  - AC profile with suspend timeout

## 6) Full Emulator Migration Plan

## 6.1 Dolphin Emulator

### Install and launch parity
- Install `dolphin-emu`.
- Keep config and data paths consistent:
  - configs: `~/.config/dolphin-emu`
  - data: `~/.local/share/dolphin-emu`

### Input/adapter support
- Install/enable required udev rules for Dolphin.
- Verify user can access adapter/input devices without running as root.

### Synced state
- Confirm Syncthing folder mappings for:
  - `GC`
  - `Wii`
  - `Profiles`
  - ROM directory

### Validation
- Game launch works.
- Controller mapping loads.
- Saves and profiles sync correctly across devices.

## 6.2 PrimeHack

### Install and path parity
- Install PrimeHack build/package compatible with target distro.
- Preserve your wrapper behavior:
  - launch PrimeHack with user dir forced to:
    - `~/.local/share/primehack`

### Desktop integration
- Keep `primehack.desktop` launcher using distro binary path.

### Synced state
- Confirm Syncthing mappings for:
  - `~/.local/share/primehack/GC`
  - `~/.local/share/primehack/Wii`
  - `~/.local/share/primehack/Config/Profiles`

### Optional advanced tuning
- `gcadapter-oc-kmod` equivalent is optional:
  - use only if DKMS/module is available and stable for your kernel
  - do not block migration on this

### Validation
- PrimeHack boots from launcher and CLI.
- Metroid Prime inputs/profiles match expectations.
- Save/profile sync remains healthy.

## 6.3 mGBA

### Install and data parity
- Install `mgba`.
- Keep ROM path:
  - `~/Documents/mgba`

### Sync behavior
- Ensure `~/Documents/mgba` remains in Syncthing and is conflict-free.

### Validation
- ROMs open from expected directory.
- Save files remain consistent across machines.

## 6.4 RetroArch (with bsnes-hd core)

### Install parity
- Install RetroArch and the `bsnes-hd` core (or nearest distro equivalent package set).
- Verify core availability in RetroArch core list.

### Save/state paths
- Decide and pin explicit save/state directories if needed (to avoid distro defaults changing path behavior).
- If you want these synced, add to Syncthing explicitly.

### Validation
- SNES game launch with bsnes-hd works.
- Shaders/perf acceptable on each host.

## 6.5 Steam + local game transfer behavior

### Install parity
- Install Steam with 32-bit runtime support.
- Enable equivalent behavior for:
  - Remote Play
  - local network game transfer
  - dedicated server firewall openings where applicable

### Validation
- Steam launches and signs in.
- Remote/local transfer features discover peers.

## 6.6 Emulator Controller/USB Checklist

Run this checklist on each host:
- User in required groups for input/device access.
- Udev rules active and reloaded.
- Adapter visible after boot/replug.
- Dolphin and PrimeHack both detect controller.
- No permission-denied logs in journal when opening adapter.

## 7) Rollout Order (Manual)
1. Rebuild core system services and firewall.
2. Set up Flatpak + AM2R override.
3. Install Nix (multi-user) for dev-only usage, verify flakes work, and keep it separate from system/dotfiles config.
4. Configure Syncthing devices/folders and validate green state.
5. Apply session defaults/autostart behavior.
6. Apply KDE settings/rules/script and desktop entries.
7. Migrate and validate emulators (Dolphin -> PrimeHack -> mGBA -> RetroArch -> Steam features).
8. Replicate host-specific boot/swap/power differences.

## 8) Final Acceptance Checklist
- NetworkManager, Bluetooth, Docker, display manager, and Syncthing are all active.
- Firewall ports match Nix config.
- Flatpak remote/app/override are in place.
- Nix is installed and usable for project workflows (`nix --version`, `nix flake show` works in your repos).
- MIME defaults and autostart behavior match host intent.
- KDE panels/shortcuts/window rules/power behavior match expected UX.
- Dolphin/PrimeHack/mGBA/RetroArch/Steam behavior matches current workflow.
- Syncthing folders for emulator data are all healthy and up to date.

## 9) Nix on Arch/Ubuntu (dev tool only)

### Intent
- Keep Nix for per-project tooling, shells, and flakes.
- Do not use Nix to manage host OS services, bootloader, or global desktop config.

### Install approach (both distros)
- Use Determinate Systems installer (recommended) or official Nix installer in multi-user mode.
- Enable flakes and `nix-command`.
- Keep Nix config under `~/.config/nix/nix.conf` for user overrides (for example `download-buffer-size`).

### Arch-specific notes
- Install Nix after core networking and user setup are stable.
- Ensure your shell initialization keeps both distro package paths and Nix profile paths usable.

### Ubuntu-specific notes
- Install Nix after base packages and sudo/user setup.
- Verify required build tools are present (`curl`, `git`, `xz-utils`, SSL certs), then run installer.

### Validation
- `nix --version`
- `nix flake --help`
- In one repo with a flake: `nix develop -c fish` (or shell of choice)
- Confirm this works without changing system service management.
