#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

HOST="$(cat /etc/hostname)"

msg "=== Session Defaults Configuration ==="

BROWSER_DESKTOP="vivaldi-stable.desktop"
if [[ "$HOST" == "mini" ]]; then
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

if [[ "$HOST" == "mini" ]]; then
  ensure_symlink /usr/share/applications/brave-browser.desktop "$HOME/.config/autostart/brave-browser.desktop"
# else
  # ensure_symlink /usr/share/applications/vivaldi-stable.desktop "$HOME/.config/autostart/vivaldi-stable.desktop"
  # ensure_symlink /usr/share/applications/obsidian.desktop "$HOME/.config/autostart/obsidian.desktop"
  # ensure_symlink /usr/share/applications/code.desktop "$HOME/.config/autostart/code.desktop"
  # rm -f "$HOME/.config/autostart/brave-browser.desktop"
fi

msg "Configured MIME defaults and autostart for host=$HOST"
msg "=== Session Defaults Configuration Complete ==="
