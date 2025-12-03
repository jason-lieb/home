{ pkgs, hostname, ... }:

let
  isLaptop = hostname == "laptop";
in
{
  programs.plasma = {
    enable = true;
    overrideConfig = true;

    workspace = {
      lookAndFeel = "org.kde.breezedark.desktop";
      colorScheme = "BreezeDark";
      theme = "breeze-dark";
      cursor = {
        theme = "breeze_cursors";
        size = 24;
      };
      wallpaper = ../wallpaper.png;
    };

    kwin = {
      virtualDesktops = {
        number = 4;
        rows = 1;
      };
    };

    kscreenlocker.autoLock = false;

    krunner.position = "center";

    shortcuts = {
      "org.kde.krunner.desktop"._launch = "Meta";

      kwin = {
        "Window Quick Tile Left" = "Meta+Left";
        "Window Quick Tile Right" = "Meta+Right";
        "Window Maximize" = "Meta+Up";
        "Window Minimize" = "Meta+Down";

        "Switch One Desktop to the Left" = "Ctrl+Alt+Left";
        "Switch One Desktop to the Right" = "Ctrl+Alt+Right";
        "Window One Desktop to the Left" = "Ctrl+Alt+Shift+Left";
        "Window One Desktop to the Right" = "Ctrl+Alt+Shift+Right";

        "Overview" = "Ctrl+Meta";
      };
    };

    panels = [
      {
        location = "bottom";
        screen = 0;
        floating = true;
        lengthMode = "fit";
        hiding = "autohide";
        widgets = [
          {
            iconTasks.launchers = [
              "applications:org.kde.dolphin.desktop"
              "applications:vivaldi-stable.desktop"
              "applications:obsidian.desktop"
              "applications:com.mitchellh.ghostty.desktop"
              "applications:cursor.desktop"
            ];
          }
        ];
      }
      {
        location = "top";
        screen = 0;
        floating = false;
        lengthMode = "fit";
        hiding = "autohide";
        widgets = [
          { systemTray.items.hidden = [ "cursor" ]; }
          { digitalClock.time.showSeconds = "never"; }
        ];
      }
    ];

    configFile = {
      "dolphinrc"."General"."ShowHiddenFiles" = true;

      # Disable splash screen
      "ksplashrc"."KSplash"."Engine" = "none";
      "ksplashrc"."KSplash"."Theme" = "none";

      # Fix vivaldi session restoration
      "ksmserverrc"."General"."loginMode" = "emptySession";
      "ksmserverrc"."General"."excludeApps" = "vivaldi";

      "kdeconnect"."General"."Enabled" = true;

      "kdeglobals"."KDE"."AnimationDurationFactor" = 0;
      "kdeglobals"."General"."BellVisible" = false;

      "kwinrc"."NightColor" = {
        Active = true;
        Mode = "Times";
        EveningBeginFixed = 2000;
        MorningBeginFixed = 700;
        NightTemperature = 2800;
      };
    };

    input = {
      keyboard.numlockOnStartup = "on";
      touchpads =
        if isLaptop then
          [
            {
              enable = true;
              name = "SYNA2BA6:00 06CB:CEF5 Touchpad";
              vendorId = "06CB";
              productId = "CEF5";
              tapToClick = true;
              naturalScroll = true;
              pointerSpeed = 0.5;
              rightClickMethod = "twoFingers";
            }
          ]
        else
          [ ];
    };

    powerdevil =
      if isLaptop then
        {
          AC = {
            autoSuspend = {
              action = "sleep";
              idleTimeout = 3600; # 1 hour
            };
            dimDisplay = {
              enable = true;
              idleTimeout = 600; # 10 minutes
            };
            turnOffDisplay = {
              idleTimeout = 900; # 15 minutes
            };
            powerProfile = "performance";
          };

          battery = {
            autoSuspend = {
              action = "sleep";
              idleTimeout = 1200; # 20 minutes
            };
            dimDisplay = {
              enable = true;
              idleTimeout = 180; # 3 minutes
            };
            turnOffDisplay = {
              idleTimeout = 300; # 5 minutes
            };
            powerProfile = "balanced";
          };

          lowBattery = {
            autoSuspend = {
              action = "sleep";
              idleTimeout = 300;
            };
            powerProfile = "powerSaving";
          };
        }
      else
        { };

  };

  home.packages = with pkgs.kdePackages; [
    bluedevil # Bluetooth manager
    bluez-qt # Bluetooth QML bindings
    filelight # Disk usage analyzer
    kcalc
    kcolorchooser # Color picker
    krdc # Remote desktop client
    ksshaskpass # SSH passphrase dialog for KDE Wallet
    plasma-browser-integration # WHY ISN'T THIS WORKING
  ];

  home.sessionVariables = {
    SSH_ASKPASS = "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
    SSH_ASKPASS_REQUIRE = "prefer";
  };
}
