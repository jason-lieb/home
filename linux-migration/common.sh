#!/usr/bin/env bash
set -euo pipefail

TARGET_USER="${TARGET_USER:-jason}"
TARGET_HOST="${TARGET_HOST:-desktop}" # desktop|laptop|mini|z560
ENABLE_PASSWORDLESS_SUDO="${ENABLE_PASSWORDLESS_SUDO:-false}"

log() {
  printf "\n[%s] %s\n" "$(date +'%H:%M:%S')" "$*"
}

warn() {
  printf "\n[WARN] %s\n" "$*" >&2
}

die() {
  printf "\n[ERROR] %s\n" "$*" >&2
  exit 1
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    die "Run as root (sudo)."
  fi
}

user_home() {
  getent passwd "${TARGET_USER}" | cut -d: -f6
}

as_user() {
  local home
  home="$(user_home)"
  sudo -u "${TARGET_USER}" HOME="${home}" bash -lc "$*"
}

enable_service() {
  local svc="$1"
  systemctl enable --now "${svc}"
}

configure_timezone_locale() {
  log "Configuring timezone and locale"
  timedatectl set-timezone America/New_York || warn "Could not set timezone"
  if command -v locale-gen >/dev/null 2>&1; then
    if [[ -f /etc/locale.gen ]] && ! rg -q '^en_US.UTF-8 UTF-8' /etc/locale.gen; then
      echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    fi
    locale-gen || true
  fi
  cat >/etc/locale.conf <<'EOF'
LANG=en_US.UTF-8
LC_ADDRESS=en_US.UTF-8
LC_IDENTIFICATION=en_US.UTF-8
LC_MEASUREMENT=en_US.UTF-8
LC_MONETARY=en_US.UTF-8
LC_NAME=en_US.UTF-8
LC_NUMERIC=en_US.UTF-8
LC_PAPER=en_US.UTF-8
LC_TELEPHONE=en_US.UTF-8
LC_TIME=en_US.UTF-8
EOF
}

configure_hosts_entry() {
  log "Ensuring localhost.com host alias"
  if ! rg -q 'localhost\.com' /etc/hosts; then
    echo '127.0.0.1 localhost.com' >>/etc/hosts
  fi
}

set_fish_shell() {
  log "Setting fish as default shell for ${TARGET_USER}"
  local fish_bin
  fish_bin="$(command -v fish || true)"
  [[ -n "${fish_bin}" ]] || { warn "fish not installed yet"; return; }
  chsh -s "${fish_bin}" "${TARGET_USER}" || warn "Could not set default shell"
}

configure_user_env() {
  log "Configuring user environment variables"
  local home
  home="$(user_home)"
  install -d -m 0755 -o "${TARGET_USER}" -g "${TARGET_USER}" "${home}/.config/environment.d"
  cat >"${home}/.config/environment.d/10-local.conf" <<EOF
NPM_CONFIG_PREFIX=${home}/.npm-packages
PATH=${home}/.npm-packages/bin:${home}/.local/bin:%h/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EOF
  chown "${TARGET_USER}:${TARGET_USER}" "${home}/.config/environment.d/10-local.conf"
}

configure_docker_group() {
  log "Configuring docker group membership"
  getent group docker >/dev/null || groupadd docker
  usermod -aG docker "${TARGET_USER}"
  enable_service docker.service
}

configure_bluetooth_service() {
  log "Enabling bluetooth service and boot-time power on unit"
  enable_service bluetooth.service
  cat >/etc/systemd/system/bluetooth-power-on.service <<'EOF'
[Unit]
Description=Power on bluetooth adapter
After=bluetooth.service
Wants=bluetooth.service

[Service]
Type=oneshot
ExecStart=/bin/bash -lc 'for _ in {1..30}; do bluetoothctl show >/dev/null 2>&1 && break; sleep 2; done; bluetoothctl power on'

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  enable_service bluetooth-power-on.service
}

configure_firewall_ufw() {
  log "Configuring UFW firewall parity"
  command -v ufw >/dev/null 2>&1 || { warn "ufw not installed, skipping"; return; }
  ufw --force enable
  for p in 3000 5432 5434 8384 19000 19001 22000; do
    ufw allow "${p}/tcp"
  done
  for p in 22000 21027; do
    ufw allow "${p}/udp"
  done
}

configure_flatpak() {
  log "Configuring Flatpak (Flathub + AM2R override)"
  command -v flatpak >/dev/null 2>&1 || { warn "flatpak not installed"; return; }
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
  flatpak install -y flathub io.github.am2r_community_developers.AM2RLauncher || warn "AM2R install failed"
  flatpak override --user io.github.am2r_community_developers.AM2RLauncher --filesystem=/run/udev:ro || true
}

configure_syncthing() {
  log "Configuring Syncthing user service"
  enable_service syncthing@${TARGET_USER}.service || true
  loginctl enable-linger "${TARGET_USER}" || true
  if ! as_user "systemctl --user enable --now syncthing"; then
    warn "Could not start user syncthing service non-interactively. Run after login: systemctl --user enable --now syncthing"
  fi

  local home
  home="$(user_home)"
  install -d -m 0755 -o "${TARGET_USER}" -g "${TARGET_USER}" \
    "${home}/.local/share/syncthing" \
    "${home}/.local/share/dolphin-emu/GC" \
    "${home}/.local/share/dolphin-emu/Wii" \
    "${home}/.config/dolphin-emu/Profiles" \
    "${home}/Documents/dolphin" \
    "${home}/Documents/mgba" \
    "${home}/.local/share/primehack/GC" \
    "${home}/.local/share/primehack/Wii" \
    "${home}/.local/share/primehack/Config/Profiles" \
    "${home}/Documents/am2r" \
    "${home}/Documents/snes"
}

configure_mime_defaults() {
  log "Configuring MIME defaults"
  local home browser
  home="$(user_home)"
  browser="vivaldi-stable.desktop"
  [[ "${TARGET_HOST}" == "mini" ]] && browser="brave-browser.desktop"
  install -d -m 0755 -o "${TARGET_USER}" -g "${TARGET_USER}" "${home}/.config"
  cat >"${home}/.config/mimeapps.list" <<EOF
[Default Applications]
application/zip=org.kde.dolphin.desktop
application/pdf=org.kde.okular.desktop
text/html=${browser}
video/mp4=${browser}
x-scheme-handler/http=${browser}
x-scheme-handler/https=${browser}
image/jpeg=org.kde.gwenview.desktop
image/png=org.kde.gwenview.desktop
EOF
  chown "${TARGET_USER}:${TARGET_USER}" "${home}/.config/mimeapps.list"
}

configure_autostart() {
  log "Configuring host-specific autostart entries"
  local home
  home="$(user_home)"
  install -d -m 0755 -o "${TARGET_USER}" -g "${TARGET_USER}" "${home}/.config/autostart"

  rm -f "${home}/.config/autostart/brave-browser.desktop" \
    "${home}/.config/autostart/vivaldi-stable.desktop" \
    "${home}/.config/autostart/obsidian.desktop" \
    "${home}/.config/autostart/cursor.desktop"

  if [[ "${TARGET_HOST}" == "mini" ]]; then
    [[ -f /usr/share/applications/brave-browser.desktop ]] && ln -s /usr/share/applications/brave-browser.desktop "${home}/.config/autostart/brave-browser.desktop"
  else
    [[ -f /usr/share/applications/vivaldi-stable.desktop ]] && ln -s /usr/share/applications/vivaldi-stable.desktop "${home}/.config/autostart/vivaldi-stable.desktop"
    [[ -f /usr/share/applications/obsidian.desktop ]] && ln -s /usr/share/applications/obsidian.desktop "${home}/.config/autostart/obsidian.desktop"
    [[ -f /usr/share/applications/cursor.desktop ]] && ln -s /usr/share/applications/cursor.desktop "${home}/.config/autostart/cursor.desktop"
  fi
  chown -h "${TARGET_USER}:${TARGET_USER}" "${home}/.config/autostart/"*.desktop 2>/dev/null || true
}

configure_kde_desktop_entries() {
  log "Creating custom KDE desktop entries and KWin script"
  local home
  home="$(user_home)"
  install -d -m 0755 -o "${TARGET_USER}" -g "${TARGET_USER}" \
    "${home}/.local/share/applications" \
    "${home}/.local/share/kwin/scripts/movewindownoswitch/contents/code"

  cat >"${home}/.local/share/applications/restart.desktop" <<'EOF'
[Desktop Entry]
Name=Restart
Comment=Restart the computer
Exec=qdbus org.kde.LogoutPrompt /LogoutPrompt promptReboot
Icon=system-reboot
Type=Application
Categories=System;
Keywords=reboot;restart;
EOF

  cat >"${home}/.local/share/applications/shutdown.desktop" <<'EOF'
[Desktop Entry]
Name=Shut Down
Comment=Shut down the computer
Exec=qdbus org.kde.LogoutPrompt /LogoutPrompt promptShutDown
Icon=system-shutdown
Type=Application
Categories=System;
Keywords=shutdown;power off;halt;
EOF

  cat >"${home}/.local/share/applications/primehack.desktop" <<'EOF'
[Desktop Entry]
Name=PrimeHack
Comment=Metroid Prime emulator (Dolphin fork)
Exec=primehack -u "$HOME/.local/share/primehack"
Icon=dolphin-emu
Type=Application
Categories=Game;Emulator;
Keywords=metroid;prime;dolphin;emulator;gamecube;wii;
EOF

  cat >"${home}/.local/share/kwin/scripts/movewindownoswitch/metadata.json" <<'EOF'
{
  "KPackageStructure": "KWin/Script",
  "X-Plasma-API": "javascript",
  "X-Plasma-MainScript": "code/main.js",
  "KPlugin": {
    "Name": "Move Window Without Switching",
    "Description": "Move windows between desktops without switching desktop",
    "Icon": "preferences-system-windows-move",
    "Id": "movewindownoswitch"
  }
}
EOF

  cat >"${home}/.local/share/kwin/scripts/movewindownoswitch/contents/code/main.js" <<'EOF'
function focusTopmostWindow(excludeWin, desktop) {
  var stackingOrder = workspace.stackingOrder;
  var targetOutput = excludeWin.output;
  for (var i = stackingOrder.length - 1; i >= 0; i--) {
    var w = stackingOrder[i];
    var onDesktop = w.desktops.length === 0 || w.desktops.indexOf(desktop) !== -1;
    var onSameOutput = w.output === targetOutput;
    if (w !== excludeWin && onDesktop && onSameOutput && !w.skipTaskbar && !w.minimized) {
      workspace.activeWindow = w;
      return;
    }
  }
}

registerShortcut("Move Window to Next Desktop (No Switch)", "Move Window to Next Desktop (No Switch)", "Ctrl+Alt+Shift+Right", function() {
  var win = workspace.activeWindow;
  if (!win || win.desktops.length === 0) return;
  var allDesktops = workspace.desktops;
  var currentDesktop = win.desktops[0];
  var currentIndex = allDesktops.indexOf(currentDesktop);
  var nextIndex = (currentIndex + 1) % allDesktops.length;
  win.desktops = [allDesktops[nextIndex]];
  focusTopmostWindow(win, currentDesktop);
});

registerShortcut("Move Window to Previous Desktop (No Switch)", "Move Window to Previous Desktop (No Switch)", "Ctrl+Alt+Shift+Left", function() {
  var win = workspace.activeWindow;
  if (!win || win.desktops.length === 0) return;
  var allDesktops = workspace.desktops;
  var currentDesktop = win.desktops[0];
  var currentIndex = allDesktops.indexOf(currentDesktop);
  var prevIndex = (currentIndex - 1 + allDesktops.length) % allDesktops.length;
  win.desktops = [allDesktops[prevIndex]];
  focusTopmostWindow(win, currentDesktop);
});
EOF

  chown -R "${TARGET_USER}:${TARGET_USER}" \
    "${home}/.local/share/applications" \
    "${home}/.local/share/kwin/scripts/movewindownoswitch"
}

configure_passwordless_sudo() {
  [[ "${ENABLE_PASSWORDLESS_SUDO}" == "true" ]] || return 0
  log "Enabling passwordless sudo for wheel/sudo group (requested)"
  if getent group wheel >/dev/null; then
    echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' >/etc/sudoers.d/99-wheel-nopasswd
  else
    echo '%sudo ALL=(ALL:ALL) NOPASSWD: ALL' >/etc/sudoers.d/99-sudo-nopasswd
  fi
  chmod 0440 /etc/sudoers.d/99-wheel-nopasswd /etc/sudoers.d/99-sudo-nopasswd 2>/dev/null || true
}

print_syncthing_manual_steps() {
  cat <<'EOF'

Manual Syncthing follow-up still required:
1) Open Syncthing UI on :8384.
2) Re-add device IDs from nixos/default.nix (desktop/laptop/mini).
3) Recreate each folder path exactly as in the Nix config.
4) Confirm all folders are "Up to Date".
EOF
}

print_emulator_notes() {
  cat <<'EOF'

Emulator follow-up checklist:
- Dolphin: verify adapter/controller permissions (udev) and profile paths.
- PrimeHack: verify binary exists (`primehack`) and launcher works with ~/.local/share/primehack.
- mGBA: verify ROM/save behavior at ~/Documents/mgba.
- RetroArch: verify bsnes-hd core availability.
- Steam: verify Remote Play + local network transfer ports/discovery.
EOF
}
