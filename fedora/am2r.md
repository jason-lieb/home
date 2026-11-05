# AM2R on Fedora

How to install and play **AM2R (Another Metroid 2 Remake)** with the AM2R
Community Updates on Fedora.

## What you need

- Fedora with Flatpak and the Flathub remote
- Your own copy of the **AM2R 1.1** zip (`AM2R_11.zip`)
- About 1 GB of free space

The launcher does not include AM2R. It verifies and patches your own AM2R 1.1
copy into the current Community Updates release (1.5.5). Nothing else will
work as a source.

## Status as of November 2026

- The native Linux `AM2RLauncher` build is broken and should not be used.
  It depends on an old WebKit and its bundled libgit2 fails on current distros.
- The Flatpak was removed from Flathub search because it uses the
  end-of-life GNOME 42 runtime, but the exact ref is still installable.
  This is the method the upstream maintainer still recommends.
- `AM2R-MinusLauncher` is a newer, unofficial command-line replacement if the
  Flatpak gives you trouble.

## Option 1: Flatpak (recommended)

### Install

```bash
flatpak remote-add --if-not-exists flathub \
  https://flathub.org/repo/flathub.flatpakrepo

flatpak install flathub io.github.am2r_community_developers.AM2RLauncher
```

Use the full application ID. The app no longer appears in `flatpak search`
or GNOME Software because it is marked end-of-life.

Give it access to udev so controllers are detected:

```bash
flatpak override --user --filesystem=/run/udev:ro \
  io.github.am2r_community_developers.AM2RLauncher
```

If GNOME Software or Discover later prompts you to uninstall the app because
its runtime is end-of-life, choose **Cancel**. `flatpak update` will also
print an end-of-life notice; that is expected.

### Install AM2R

1. Launch the launcher:

   ```bash
   flatpak run io.github.am2r_community_developers.AM2RLauncher
   ```

2. Click **Download** and wait for it to fetch the Community Update patch
   files.
3. Click **Select 1.1** and choose your `AM2R_11.zip`.
4. Click **Install**.
5. Click **Play**.

The zip must contain `AM2R.exe` at its root, not inside a subfolder. If the
launcher reports `GameIsInASubfolder`, extract the zip, re-zip the contents
directly, and try again.

### Where the files go

| What | Path |
| --- | --- |
| Launcher data, profiles, patch data | `~/.var/app/io.github.am2r_community_developers.AM2RLauncher/data/AM2RLauncher` |
| Logs | `~/.var/app/io.github.am2r_community_developers.AM2RLauncher/data/AM2RLauncher/Logs` |
| Game saves | Usually `~/.config/AM2R`; the Flatpak also exposes its own config directory |

You can open the save folder from the launcher with
**Mod Settings → Open Profile Save Folder**.

### Keep AM2R data in the Syncthing folder

The NixOS setup synced `~/Documents/am2r`. To make the Flatpak use that
directory for its profiles and patch data, run this before installing the
game:

```bash
mkdir -p "$HOME/Documents/am2r"

flatpak override --user \
  --env=AM2RLAUNCHERDATA="$HOME/Documents/am2r" \
  --filesystem="$HOME/Documents/am2r" \
  io.github.am2r_community_developers.AM2RLauncher
```

If you already installed profiles, move the contents of the Flatpak data
directory into `~/Documents/am2r` first, or simply leave the default paths.
Do not run the game on two machines at once while this folder is syncing.

## Option 2: AM2R-MinusLauncher

Use this only if the Flatpak does not work or you want to avoid the
end-of-life runtime.

```bash
sudo dnf install -y git xdelta unzip

mkdir -p ~/Applications/am2r-minuslauncher
cd ~/Applications/am2r-minuslauncher
curl -fL -o minus.zip \
  https://github.com/rm-steele/AM2R-MinusLauncher/releases/download/0.2.0/AM2R-MinusLauncher-v0.2.0-Linux-x86_64.zip
unzip -o minus.zip
chmod +x AM2R-MinusLauncher
./AM2R-MinusLauncher
```

It is a command-line program. Run it from its own directory because it
creates `profiles/` and `resources/` relative to the current working
directory.

Typical first run:

1. Give it the path to your `AM2R_11.zip`.
2. Choose **Download Patch Data**.
3. Choose **Install Community Updates**.
4. Choose **Launch a profile** and select `CommunityUpdates`.

This tool is unofficial, does not verify the integrity of the files you give
it, and is much newer than the official launcher. The official project still
recommends the Flatpak.

## Troubleshooting

- **`No remote refs found for 'flathub'`** — add Flathub with the
  `flatpak remote-add` command above, then retry.
- **App is not in `flatpak search` or GNOME Software** — it is delisted.
  Install it by its full ID:
  `flatpak install flathub io.github.am2r_community_developers.AM2RLauncher`.
- **The launcher asks to be uninstalled** — cancel the prompt. This is the
  end-of-life runtime warning, not a real problem with the install.
- **`GameIsInASubfolder`** — the AM2R 1.1 zip has a folder at its root.
  Re-zip it so `AM2R.exe` is at the top level.
- **`MissingOrInvalidAM2RExe`, `MissingOrInvalidDataWin`, or
  `MissingOrInvalidD3DX9_43Dll`** — you supplied the wrong game version.
  The launcher only accepts AM2R 1.1.
- **Controller does not work** — confirm the `/run/udev:ro` override above
  is set, reconnect the controller, and enable **Compatibility Mode** under
  the game's control options.
- **Game does not start** — run the Flatpak from a terminal to see the error:

  ```bash
  flatpak run io.github.am2r_community_developers.AM2RLauncher
  ```

  Launcher logs are in the Flatpak data directory listed above.
- **Fullscreen looks corrupted during the title screen** — this is a
  GameMaker issue. It is fixed once you reach the "A controller is
  recommended" screen in 1.5.3 and later.
- **Saves are missing** — check both `~/.config/AM2R` and the Flatpak's
  config directory under
  `~/.var/app/io.github.am2r_community_developers.AM2RLauncher/config`.

## Uninstall

```bash
flatpak uninstall io.github.am2r_community_developers.AM2RLauncher
flatpak uninstall --unused
```

Uninstalling the Flatpak does not delete your saves in `~/.config/AM2R` or
the launcher data in `~/.var/app/io.github.am2r_community_developers.AM2RLauncher`.
