#!/bin/bash
set -euo pipefail

echo "=== Session Defaults Configuration ==="

write_if_changed() {
  local target="$1"
  local content="$2"
  local tmp_file
  tmp_file="$(mktemp)"
  printf "%s" "$content" > "$tmp_file"
  if [[ ! -f "$target" ]] || ! cmp -s "$tmp_file" "$target"; then
    cp "$tmp_file" "$target"
  fi
  rm -f "$tmp_file"
}

ensure_symlink() {
  local src="$1"
  local dest="$2"

  if [[ ! -f "$src" ]]; then
    rm -f "$dest"
    return 0
  fi

  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    return 0
  fi

  if [[ -e "$dest" && ! -L "$dest" ]]; then
    local backup_path="${dest}.backup"
    if [[ -e "$backup_path" ]]; then
      backup_path="${dest}.backup.$(date +%s)"
    fi
    mv "$dest" "$backup_path"
  fi

  rm -f "$dest"
  ln -s "$src" "$dest"
}

BROWSER_DESKTOP="vivaldi-stable.desktop"
if [[ "$(hostname)" == "mini" ]]; then
  BROWSER_DESKTOP="brave-browser.desktop"
fi

mkdir -p "$HOME/.config" "$HOME/.config/autostart"

MIMEAPPS_CONTENT="$(cat <<EOF
[Default Applications]
application/zip=org.kde.dolphin.desktop
application/pdf=org.kde.okular.desktop
text/html=${BROWSER_DESKTOP}
video/mp4=${BROWSER_DESKTOP}
x-scheme-handler/http=${BROWSER_DESKTOP}
x-scheme-handler/https=${BROWSER_DESKTOP}
image/jpeg=org.kde.gwenview.desktop
image/png=org.kde.gwenview.desktop
EOF
)"
write_if_changed "$HOME/.config/mimeapps.list" "$MIMEAPPS_CONTENT"

if [[ "$(hostname)" == "mini" ]]; then
  ensure_symlink /usr/share/applications/brave-browser.desktop "$HOME/.config/autostart/brave-browser.desktop"
  rm -f "$HOME/.config/autostart/vivaldi-stable.desktop" "$HOME/.config/autostart/obsidian.desktop" "$HOME/.config/autostart/code.desktop"
else
  ensure_symlink /usr/share/applications/vivaldi-stable.desktop "$HOME/.config/autostart/vivaldi-stable.desktop"
  ensure_symlink /usr/share/applications/obsidian.desktop "$HOME/.config/autostart/obsidian.desktop"
  ensure_symlink /usr/share/applications/code.desktop "$HOME/.config/autostart/code.desktop"
  rm -f "$HOME/.config/autostart/brave-browser.desktop"
fi

echo "Configured MIME defaults and autostart for host=$(hostname)"
echo "=== Session Defaults Configuration Complete ==="
