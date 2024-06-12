{ config, pkgs, lib, ... }:

{
  services.xserver = {
    displayManager.gdm = {
      enable = true;
      wayland = true; # Comment out to switch to X11
    };

    desktopManager.gnome.enable = true;
  };

  environment.systemPackages = with pkgs; [
    gnome.gnome-tweaks
    gnome-extension-manager
    gnomeExtensions.caffeine
  ];

  environment.gnome.excludePackages = with pkgs.gnome; [
    baobab
    cheese
    eog
    epiphany
    gedit
    simple-scan
    totem
    yelp
    evince
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

    profiles.user.databases = [{
      settings = with lib.gvariant; {
        "org/gnome/desktop/wm/keybindings".switch-windows = [ "<Alt>Tab" ];

        "org/gnome/desktop/interface" = {
          clock-format = "12h";
          color-scheme = "prefer-dark";
        };

        "org/gnome/desktop/notifications/application/gnome-power-panel" = {
          application-id = "gnome-power-panel.desktop";
          enable = false;
        };

        "org/gnome/desktop/peripherals/touchpad".tap-to-click = true;

        "org/gnome/desktop/peripherals/keyboard".numlock-state = true;

        "org/gnome/desktop/screensaver".lock-enabled = false;

        "org/gnome/desktop/wm/preferences" = {
          auto-raise = false;
          button-layout = "appmenu:minimize,maximize,close";
          focus-mode = "click";
          num-workspace =
            4.0; # Doesn't work, likely related to the fact I can't set it to 4 instead of 4.0
        };

        "org/gnome/mutter" = {
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

        "org/gnome/shell" = {
          disable-user-extensions = false;
          enabled-extensions = [
            "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
            "caffeine@patapon.info"
            "display-brightness-ddcutil@themightydeity.github.com"
          ];
          favorite-apps = [
            "org.gnome.Nautilus.desktop"
            "brave-browser.desktop"
            "Alacritty.desktop"
            "code.desktop"
            "org.gnome.Software.desktop"
          ];
        };

        "org/gnome/shell/app-switcher".current-workspace-only = true;

        "org/gnome/shell/extensions/caffeine" = {
          duration-timer = 2.0;
          indicator-position-max = 4.0;
          screen-blank = "always";
          show-notifications = false;
        };

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
    }];
  };
}
