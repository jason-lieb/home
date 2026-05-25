#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

HOST="$(cat /etc/hostname)"

msg "=== KDE Plasma Configuration ==="

# ============================================
# Appearance
# ============================================
msg "Configuring appearance..."

# Look and Feel
kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breezedark.desktop"

# Color Scheme
kwriteconfig6 --file kdeglobals --group General --key ColorScheme "BreezeDark"

# Cursor
kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme "breeze_cursors"
kwriteconfig6 --file kcminputrc --group Mouse --key cursorSize 24

# ============================================
# Virtual Desktops
# ============================================
msg "Configuring virtual desktops..."

kwriteconfig6 --file kwinrc --group Desktops --key Number 4
kwriteconfig6 --file kwinrc --group Desktops --key Rows 1

# ============================================
# Keyboard Shortcuts
# ============================================
msg "Configuring keyboard shortcuts..."

# KRunner - Meta key to launch
kwriteconfig6 --file kglobalshortcutsrc --group "org.kde.krunner.desktop" --key "_launch" "Meta,Meta,KRunner"

# Window tiling
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Quick Tile Left" "Meta+Left,Meta+Left,Quick Tile Window to the Left"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Quick Tile Right" "Meta+Right,Meta+Right,Quick Tile Window to the Right"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Maximize" "Meta+Up,Meta+Up,Maximize Window"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Minimize" "Meta+Down,Meta+Down,Minimize Window"

# Desktop switching
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch One Desktop to the Left" "Ctrl+Alt+Left,Ctrl+Alt+Left,Switch One Desktop to the Left"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch One Desktop to the Right" "Ctrl+Alt+Right,Ctrl+Alt+Right,Switch One Desktop to the Right"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Overview" "Ctrl+Meta,Ctrl+Meta,Toggle Overview"

# ============================================
# KWin Script: Move Window Without Switching
# ============================================
msg "Installing KWin script for window movement..."

KWIN_SCRIPT_DIR="$HOME/.local/share/kwin/scripts/movewindownoswitch"
mkdir -p "$KWIN_SCRIPT_DIR/contents/code"

# Create metadata.json
cat > "$KWIN_SCRIPT_DIR/metadata.json" << 'METADATA'
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
METADATA

# Create main.js
cat > "$KWIN_SCRIPT_DIR/contents/code/main.js" << 'MAINJS'
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

registerShortcut(
    "Move Window to Next Desktop (No Switch)",
    "Move Window to Next Desktop (No Switch)",
    "Ctrl+Alt+Shift+Right",
    function() {
        var win = workspace.activeWindow;
        if (!win || win.desktops.length === 0) return;

        var allDesktops = workspace.desktops;
        var currentDesktop = win.desktops[0];
        var currentIndex = allDesktops.indexOf(currentDesktop);
        var nextIndex = (currentIndex + 1) % allDesktops.length;

        win.desktops = [allDesktops[nextIndex]];
        focusTopmostWindow(win, currentDesktop);
    }
);

registerShortcut(
    "Move Window to Previous Desktop (No Switch)",
    "Move Window to Previous Desktop (No Switch)",
    "Ctrl+Alt+Shift+Left",
    function() {
        var win = workspace.activeWindow;
        if (!win || win.desktops.length === 0) return;

        var allDesktops = workspace.desktops;
        var currentDesktop = win.desktops[0];
        var currentIndex = allDesktops.indexOf(currentDesktop);
        var prevIndex = (currentIndex - 1 + allDesktops.length) % allDesktops.length;

        win.desktops = [allDesktops[prevIndex]];
        focusTopmostWindow(win, currentDesktop);
    }
);
MAINJS

# Enable the script
kwriteconfig6 --file kwinrc --group Plugins --key movewindownoswitchEnabled true

# ============================================
# Other Plasma Settings
# ============================================
msg "Configuring other Plasma settings..."

# Disable animations
kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor 1

# Night Color
kwriteconfig6 --file kwinrc --group NightColor --key Active true
kwriteconfig6 --file kwinrc --group NightColor --key NightTemperature 2800

# Screen locker
kwriteconfig6 --file kscreenlockerrc --group Daemon --key Autolock false
kwriteconfig6 --file kscreenlockerrc --group Daemon --key LockOnResume true

# NumLock on at boot
kwriteconfig6 --file kcminputrc --group Keyboard --key NumLock 0

# Dolphin - show hidden files
kwriteconfig6 --file dolphinrc --group General --key ShowHiddenFiles true

# Disable splash screen
kwriteconfig6 --file ksplashrc --group KSplash --key Engine "none"
kwriteconfig6 --file ksplashrc --group KSplash --key Theme "none"

# Disable busy cursor on app launch
kwriteconfig6 --file klaunchrc --group FeedbackStyle --key BusyCursor false

# Disable visible bell
kwriteconfig6 --file kdeglobals --group General --key BellVisible false

# Night time schedule
kwriteconfig6 --file knighttimerc --group General --key Source "Times"
kwriteconfig6 --file knighttimerc --group Times --key SunriseStart "07:00:00"
kwriteconfig6 --file knighttimerc --group Times --key SunsetStart "20:00:00"

# Empty session restore (don't restore previous session)
kwriteconfig6 --file ksmserverrc --group General --key loginMode "emptySession"

# KRunner position (free floating in center)
kwriteconfig6 --file krunnerrc --group General --key FreeFloating true

# ============================================
# Window Rules
# ============================================
msg "Configuring window rules..."

# Create window rules for maximizing apps on start
RULES_FILE="$HOME/.config/kwinrulesrc"

# Configure rules for commonly used apps
if [[ "$HOST" == "desktop" ]]; then
cat > "$RULES_FILE" << 'WINDOWRULES'
[1]
Description=Default window size 1600x1000
size=1600,1000
sizerule=1
types=1
typesrule=2

[General]
count=1
rules=1
WINDOWRULES
else
cat > "$RULES_FILE" << 'WINDOWRULES'
[General]
count=0
WINDOWRULES
fi

# Touchpad (laptop only)
if [[ "$HOST" == "laptop" ]]; then
    msg "Configuring touchpad..."
    kwriteconfig6 --file touchpadrc --group "SYNA2BA6:00 06CB:CEF5 Touchpad" --key TapToClick true
    kwriteconfig6 --file touchpadrc --group "SYNA2BA6:00 06CB:CEF5 Touchpad" --key NaturalScroll true
    kwriteconfig6 --file touchpadrc --group "SYNA2BA6:00 06CB:CEF5 Touchpad" --key PointerAcceleration "0.5"
fi

# Power profile policies by host
if [[ "$HOST" == "laptop" ]]; then
    # AC
    kwriteconfig6 --file powermanagementprofilesrc --group AC --group DimDisplay --key idleTime 600000
    kwriteconfig6 --file powermanagementprofilesrc --group AC --group DPMSControl --key idleTime 900000
    kwriteconfig6 --file powermanagementprofilesrc --group AC --group DPMSControl --key lockBeforeTurnOff 60000
    kwriteconfig6 --file powermanagementprofilesrc --group AC --group SuspendSession --key suspendType 1
    kwriteconfig6 --file powermanagementprofilesrc --group AC --group SuspendSession --key idleTime 3600000
    kwriteconfig6 --file powermanagementprofilesrc --group AC --group Performance --key PowerProfile "performance"
    kwriteconfig6 --file powermanagementprofilesrc --group AC --group KeyboardBrightness --key value 100
    # Battery
    kwriteconfig6 --file powermanagementprofilesrc --group Battery --group DimDisplay --key idleTime 300000
    kwriteconfig6 --file powermanagementprofilesrc --group Battery --group DPMSControl --key idleTime 600000
    kwriteconfig6 --file powermanagementprofilesrc --group Battery --group DPMSControl --key lockBeforeTurnOff 60000
    kwriteconfig6 --file powermanagementprofilesrc --group Battery --group SuspendSession --key suspendType 1
    kwriteconfig6 --file powermanagementprofilesrc --group Battery --group SuspendSession --key idleTime 1200000
    kwriteconfig6 --file powermanagementprofilesrc --group Battery --group Performance --key PowerProfile "balanced"
    kwriteconfig6 --file powermanagementprofilesrc --group Battery --group KeyboardBrightness --key value 100
    # Low Battery
    kwriteconfig6 --file powermanagementprofilesrc --group LowBattery --group DPMSControl --key idleTime 180000
    kwriteconfig6 --file powermanagementprofilesrc --group LowBattery --group DPMSControl --key lockBeforeTurnOff 30000
    kwriteconfig6 --file powermanagementprofilesrc --group LowBattery --group SuspendSession --key suspendType 1
    kwriteconfig6 --file powermanagementprofilesrc --group LowBattery --group SuspendSession --key idleTime 300000
    kwriteconfig6 --file powermanagementprofilesrc --group LowBattery --group Performance --key PowerProfile "powerSaving"
    kwriteconfig6 --file powermanagementprofilesrc --group LowBattery --group KeyboardBrightness --key value 25
elif [[ "$HOST" == "mini" ]]; then
    kwriteconfig6 --file powermanagementprofilesrc --group AC --group DimDisplay --key idleTime 600000
    kwriteconfig6 --file powermanagementprofilesrc --group AC --group DPMSControl --key idleTime 1200000
    kwriteconfig6 --file powermanagementprofilesrc --group AC --group DPMSControl --key lockBeforeTurnOff 180000
    kwriteconfig6 --file powermanagementprofilesrc --group AC --group SuspendSession --key suspendType 0
    kwriteconfig6 --file powermanagementprofilesrc --group AC --group SuspendSession --key idleTime 0
    kwriteconfig6 --file powermanagementprofilesrc --group AC --group Performance --key PowerProfile "performance"
else
    kwriteconfig6 --file powermanagementprofilesrc --group AC --group DimDisplay --key idleTime 600000
    kwriteconfig6 --file powermanagementprofilesrc --group AC --group DPMSControl --key idleTime 1200000
    kwriteconfig6 --file powermanagementprofilesrc --group AC --group DPMSControl --key lockBeforeTurnOff 180000
    kwriteconfig6 --file powermanagementprofilesrc --group AC --group SuspendSession --key suspendType 1
    kwriteconfig6 --file powermanagementprofilesrc --group AC --group SuspendSession --key idleTime 3600000
    kwriteconfig6 --file powermanagementprofilesrc --group AC --group Performance --key PowerProfile "performance"
fi

# ============================================
# Wallpaper
# ============================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WALLPAPER_SRC="$SCRIPT_DIR/../../wallpaper.png"
WALLPAPER_DEST="$HOME/.local/share/wallpapers/wallpaper.png"

msg "Installing wallpaper..."
mkdir -p "$HOME/.local/share/wallpapers"
if [[ ! -f "$WALLPAPER_DEST" ]] || ! cmp -s "$WALLPAPER_SRC" "$WALLPAPER_DEST"; then
    cp "$WALLPAPER_SRC" "$WALLPAPER_DEST"
fi

if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
    plasma-apply-wallpaperimage "$WALLPAPER_DEST" || true
fi

# ============================================
# Panels Layout
# ============================================
msg "Configuring Plasma panels..."
if command -v qdbus >/dev/null 2>&1 && pgrep -x plasmashell >/dev/null; then
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
(function() {
    function writeLaunchers(widget, launchers) {
        widget.currentConfigGroup = ["General"];
        widget.writeConfig("launchers", launchers.join(","));
    }
try {
        var p = panels();
        for (var i = p.length - 1; i >= 0; i--) { p[i].remove(); }
        var bottom = new Panel();
        bottom.location = "bottom";
        bottom.floating = true;
        bottom.hiding = "autohide";
        bottom.lengthMode = "fit";
        var tasks = bottom.addWidget("org.kde.plasma.icontasks");
        writeLaunchers(tasks, [
            "applications:org.kde.dolphin.desktop",
            "applications:vivaldi-stable.desktop",
            "applications:com.mitchellh.ghostty.desktop",
            "applications:code.desktop"
        ]);
        bottom.currentConfigGroup = ["General"];
        bottom.writeConfig("thickness", 72);
        bottom.writeConfig("maxThickness", 72);
        var top = new Panel();
        top.location = "top";
        top.floating = false;
        top.hiding = "autohide";
        top.lengthMode = "fit";
        var tray = top.addWidget("org.kde.plasma.systemtray");
        tray.currentConfigGroup = ["General"];
        tray.writeConfig("hiddenItems", "cursor");
        var clock = top.addWidget("org.kde.plasma.digitalclock");
        clock.currentConfigGroup = ["Appearance"];
        clock.writeConfig("showSeconds", "Never");
        top.currentConfigGroup = ["General"];
        top.writeConfig("thickness", 72);
        top.writeConfig("maxThickness", 72);
    } catch (e) { }
})()' || msg "Panel config skipped (Plasma not running)"
fi

# ============================================
# Desktop Entries
# ============================================
msg "Creating desktop entries..."

mkdir -p "$HOME/.local/share/applications"

# Restart desktop entry
cat > "$HOME/.local/share/applications/restart.desktop" << 'RESTARTDESKTOP'
[Desktop Entry]
Name=Restart
Comment=Restart the computer
Exec=qdbus org.kde.LogoutPrompt /LogoutPrompt promptReboot
Icon=system-reboot
Type=Application
Categories=System;
RESTARTDESKTOP

# Shutdown desktop entry
cat > "$HOME/.local/share/applications/shutdown.desktop" << 'SHUTDOWNDESKTOP'
[Desktop Entry]
Name=Shut Down
Comment=Shut down the computer
Exec=qdbus org.kde.LogoutPrompt /LogoutPrompt promptShutDown
Icon=system-shutdown
Type=Application
Categories=System;
SHUTDOWNDESKTOP

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# ============================================
# Vivaldi KDE Browser Integration
# ============================================
msg "Configuring Vivaldi KDE browser integration..."
VIVALDI_NMH_DIR="$HOME/.config/vivaldi/NativeMessagingHosts"
mkdir -p "$VIVALDI_NMH_DIR"
PLASMA_BROWSER_HOST="$(command -v plasma-browser-integration-host 2>/dev/null || echo "/usr/bin/plasma-browser-integration-host")"
cat > "$VIVALDI_NMH_DIR/org.kde.plasma.browser_integration.json" << VIVALDI_NMH
{
  "name": "org.kde.plasma.browser_integration",
  "description": "Native connector for KDE Plasma Browser Integration",
  "path": "$PLASMA_BROWSER_HOST",
  "type": "stdio",
  "allowed_origins": ["chrome-extension://cimiefiiaegbelhefglklhhakcgmhkai/"]
}
VIVALDI_NMH

# ============================================
# Monitor Layout (kscreen-doctor)
# ============================================
if command -v kscreen-doctor >/dev/null 2>&1; then
    msg "Configuring monitor layout..."
    if [[ "$HOST" == "desktop" ]]; then
        kscreen-doctor \
            output.DP-1.enable \
            output.DP-1.mode.2560x1440@165 \
            output.DP-1.position.0,0 \
            output.DP-1.primary \
            2>/dev/null || echo "NOTE: Monitor layout failed — adjust output names with 'kscreen-doctor -o'"
    elif [[ "$HOST" == "laptop" ]]; then
        kscreen-doctor \
            output.eDP-1.enable \
            output.eDP-1.mode.2256x1504@60 \
            output.eDP-1.position.0,0 \
            output.eDP-1.primary \
            2>/dev/null || echo "NOTE: Monitor layout failed — adjust output names with 'kscreen-doctor -o'"
    fi
fi

# ============================================
# Reload KWin
# ============================================
msg "Reloading KWin configuration..."
if pgrep -x "kwin_wayland" > /dev/null || pgrep -x "kwin_x11" > /dev/null; then
    qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
fi

msg ""
msg "=== KDE Plasma Configuration Complete ==="
msg "NOTE: Log out and back in for all changes to take effect."
