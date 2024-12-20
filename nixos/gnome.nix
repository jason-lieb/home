{ pkgs, ... }:

{
  services.xserver = {
    desktopManager.gnome.enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
  };

  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnome-extension-manager
  ];

  environment.gnome.excludePackages = with pkgs; [
    baobab
    cheese
    eog
    epiphany
    simple-scan
    totem
    yelp
    file-roller
    geary
    seahorse

    gnome-calendar
    gnome-characters
    gnome-clocks
    gnome-contacts
    gnome-font-viewer
    gnome-logs
    gnome-maps
    gnome-music
    gnome-screenshot
    gnome-weather
  ];

  programs.dconf = {
    enable = true;

    profiles.user.databases = [
      {
        settings = {
          "org/gtk/gtk4/settings/file-chooser" = {
            show-hidden = true;
          };

          "org/gnome/desktop/background" = {
            color-shading-type = "solid";
            picture-options = "zoom";
            picture-uri = "file://" + ../wallpaper.png;
          };

          "org/gnome/desktop/wm/keybindings".switch-windows = [ "<Alt>Tab" ];
          "org/gnome/desktop/wm/keybindings".switch-windows-backwards = [ "<Shift><Alt>Tab" ];

          "org/gnome/desktop/interface" = {
            clock-format = "12h";
            color-scheme = "prefer-dark";
          };

          "org/gnome/desktop/datetime".automatic-timezone = true;

          "org/gnome/desktop/notifications/application/gnome-power-panel" = {
            application-id = "gnome-power-panel.desktop";
            enable = false;
          };

          "org/gnome/desktop/peripherals/touchpad" = {
            speed = 0.5;
            tap-to-click = true;
          };

          "org/gnome/desktop/peripherals/keyboard".numlock-state = true;

          "org/gnome/desktop/screensaver".lock-enabled = false;

          "org/gnome/desktop/wm/preferences" = {
            auto-raise = false;
            button-layout = "appmenu:minimize,maximize,close";
            focus-mode = "click";
            num-workspace = 4.0; # Doesn't work
          };

          "org/gnome/mutter" = {
            edge-tiling = true;
            center-new-windows = true;
            dynamic-workspaces = false;
            workspaces-only-on-primary = true;
          };

          "org/gnome/settings-daemon/plugins/color" = {
            night-light-enabled = true;
            night-light-temperature = 3700.0;
          };

          "org/gnome/settings-daemon/plugins/power" = {
            sleep-inactive-ac-timeout = 3600.0;
            sleep-inactive-ac-type = "suspend";
            power-mode = "performance";
          };

          "org/gnome/desktop/session" = {
            idle-delay = "uint32 900";
          };

          "org/gnome/Console/audible-bell" = {
            enabled = false;
          };

          "org/gnome/shell" = {
            disable-user-extensions = false;
            enabled-extensions = [
              "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
              "display-brightness-ddcutil@themightydeity.github.com"
            ];
            favorite-apps = [
              "org.gnome.Nautilus.desktop"
              "brave-browser.desktop"
              "obsidian.desktop"
              "Alacritty.desktop"
              "code.desktop"
              "code-cursor.desktop"
              "org.gnome.Software.desktop"
            ];
            last-selected-power-profile = "performance";
          };

          "org/gnome/shell/app-switcher".current-workspace-only = true;

          "org/gnome/shell/extensions/display-brightness-ddcutil" = {
            ddcutil-binary-path = "/run/current-system/sw/bin/ddcutil";
            ddcutil-queue-ms = 130.0;
            ddcutil-sleep-multiplier = 40.0;
            decrease-brightness-shortcut = [ "<Control>XF86MonBrightnessDown" ];
            increase-brightness-shortcut = [ "<Control>XF86MonBrightnessUp" ];
            only-all-slider = true;
            position-system-menu = 3.0;
            show-all-slider = true;
            step-change-keyboard = 2.0;
          };

          "org/gnome/tweaks".show-extensions-notice = false;
        };
      }
    ];
  };
}
