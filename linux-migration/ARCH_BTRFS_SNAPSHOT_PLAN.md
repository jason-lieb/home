# Arch Stability, Snapshot, and Recovery Plan

## Goal
Build a fresh Arch install with reliable rollback paths, low operational churn, and repeatable update behavior across hosts.

## Baseline (Fresh Install)
- Create Btrfs subvolumes during install:
  - `@` (root), `@home`, `@var_log`, `@snapshots`, optional `@var_cache`.
- Mount with desktop-friendly options:
  - `noatime,compress=zstd,ssd,space_cache=v2` (plus `discard=async` if desired).
- Keep `/boot` as separate EFI partition (vfat), with root on Btrfs.
- Pick one kernel track (`linux` or `linux-lts`) and keep it consistent.
- Keep one bootloader strategy (prefer GRUB if using `grub-btrfs` boot entries).

## Snapshot Stack
- **Recommended default (CLI-centric):**
  - `snapper`
  - `snap-pac`
  - `grub-btrfs`
  - optional `btrfs-assistant`
- **Alternative (GUI-first):**
  - `timeshift`
  - optional `grub-btrfs`

## Recommended Implementation Order
1. Install Arch on Btrfs with the subvolume layout above.
2. Install bootloader (GRUB if snapshot boot entries are needed).
3. Install snapshot tooling (Snapper stack preferred).
4. Configure retention (hourly/daily/weekly pruning).
5. Add pre-risk manual snapshot habit:
   - before kernel, graphics, bootloader, Plasma, or major config changes.
6. Validate rollback end-to-end:
   - one rollback from boot menu and one from userspace.

## Boring-Stable Operational Guardrails
- Keep package source policy stable:
  - official repos first
  - AUR only for required apps (`cursor-bin`, `primehack`, etc.).
- Keep AUR list short and intentional.
- Prefer stable `-bin` AUR packages where available.
- Treat updates as a scheduled maintenance event (for example, weekly).
- Rollback first, debug second, when regressions appear.

## Weekly Maintenance Routine
1. Create a manual snapshot.
2. Run `pacman -Syu`.
3. Reboot.
4. Validate:
   - display/login
   - networking
   - audio
   - bluetooth
   - docker
   - syncthing
5. Launch key apps:
   - Cursor
   - browser
   - Dolphin
   - PrimeHack
   - Steam
6. If anything fails, rollback immediately and log the regression.

## Recovery Layers (Do Not Skip)
- **Layer 1: Local snapshots** for fast rollback of software/config breakage.
- **Layer 2: Off-disk backups** (`btrfs send/receive`, `restic`, or `borg`) for disk-loss protection.
- **Layer 3: Rescue USB** with documented restore steps.

## Integration with Repo Automation
- Add snapshot packages and setup hooks to `scripts/linux-migration/arch.sh` so new installs are snapshot-ready.
- In `scripts/linux-migration/arch.sh`, install or verify `yay` early to avoid silent package gaps.
- Add post-bootstrap verification checks for:
  - `NetworkManager.service`
  - `sddm.service`
  - `docker.service`
  - `bluetooth.service`
  - Syncthing service state
  - required app binaries

## Acceptance Criteria
- Root filesystem is Btrfs with intended subvolumes mounted correctly.
- Automatic snapshots occur on package transactions (Snapper path) or scheduled policy (Timeshift path).
- At least one rollback from boot menu and one from userspace succeeds.
- External backup restore is tested on a sample path.
- Weekly maintenance routine is documented and repeatable.
