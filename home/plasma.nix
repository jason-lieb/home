{ pkgs, hostname, ... }:

let
  isLaptop = hostname == "laptop";
  isDesktop = hostname == "desktop";
  isMini = hostname == "mini";

  inherit (import ./utils/window-rules.nix)
    maximize
    moveToSidewaysScreen
    defaultSize
    ;
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

    window-rules =
      maximize [
        "vivaldi"
        "Cursor"
        "Code"
        "obsidian"
        "github-desktop"
      ]
      ++ (
        if isDesktop then
          defaultSize
          ++ moveToSidewaysScreen [
            "obsidian"
            "vivaldi"
          ]
        else
          [ ]
      );

    kscreenlocker = {
      autoLock = false; # Don't lock on idle timeout
      lockOnResume = true; # Lock when waking from sleep
    };

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
        # "Window One Desktop to the Left" = "Ctrl+Alt+Shift+Left";
        # "Window One Desktop to the Right" = "Ctrl+Alt+Shift+Right";

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

      # Disable bouncing cursor on app launch
      "klaunchrc"."FeedbackStyle"."BusyCursor" = false;

      # Fix vivaldi session restoration
      "ksmserverrc"."General"."loginMode" = "emptySession";
      "ksmserverrc"."General"."excludeApps" = "vivaldi";

      "kdeglobals"."KDE"."AnimationDurationFactor" = 0;
      "kdeglobals"."General"."BellVisible" = false;

      "kwinrc"."NightColor" = {
        Active = true;
        Mode = "Times";
        EveningBeginFixed = 2000;
        MorningBeginFixed = 700;
        NightTemperature = 2800;
      };

      "kwinrc"."Plugins"."movewindownoswitchEnabled" = true;
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
            dimDisplay = {
              enable = true;
              idleTimeout = 600; # 10 minutes
            };
            turnOffDisplay = {
              idleTimeout = 900; # 15 minutes
              idleTimeoutWhenLocked = 60;
            };
            autoSuspend = {
              action = "sleep";
              idleTimeout = 3600; # 1 hour
            };
            powerProfile = "performance";
            keyboardBrightness = 100;
          };

          battery = {
            dimDisplay = {
              enable = true;
              idleTimeout = 300; # 5 minutes
            };
            turnOffDisplay = {
              idleTimeout = 600; # 10 minutes
              idleTimeoutWhenLocked = 60;
            };
            autoSuspend = {
              action = "sleep";
              idleTimeout = 1200; # 20 minutes
            };
            powerProfile = "balanced";
            keyboardBrightness = 100;
          };

          lowBattery = {
            turnOffDisplay = {
              idleTimeout = 180; # 3 minutes
              idleTimeoutWhenLocked = 30;
            };
            autoSuspend = {
              action = "sleep";
              idleTimeout = 300; # 5 minutes
            };
            powerProfile = "powerSaving";
            keyboardBrightness = 25;
          };
        }
      else if isMini then
        {
          AC = {
            dimDisplay = {
              enable = true;
              idleTimeout = 600; # 10 min
            };
            turnOffDisplay = {
              idleTimeout = 1200; # 20 min
              idleTimeoutWhenLocked = 180;
            };
            autoSuspend.action = "nothing";
            powerProfile = "performance";
          };
        }
      else
        {
          AC = {
            dimDisplay = {
              enable = true;
              idleTimeout = 600; # 10 min
            };
            turnOffDisplay = {
              idleTimeout = 1200; # 20 min
              idleTimeoutWhenLocked = 180;
            };
            autoSuspend = {
              action = "sleep";
              idleTimeout = 3600; # 1 hour
            };
            powerProfile = "performance";
          };
        };

  };

  home.packages = with pkgs.kdePackages; [
    bluedevil # Bluetooth manager
    bluez-qt # Bluetooth QML bindings
    filelight # Disk usage analyzer
    kcalc
    kcolorchooser # Color picker
    krdc # Remote desktop client
    ksshaskpass # SSH passphrase dialog for KDE Wallet
    plasma-browser-integration
  ];

  home.sessionVariables = {
    SSH_ASKPASS = "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
    SSH_ASKPASS_REQUIRE = "prefer";
  };

  # Custom desktop entry for quick restart access in KRunner
  home.file.".local/share/applications/restart.desktop".text = ''
    [Desktop Entry]
    Name=Restart
    Comment=Restart the computer
    Exec=/run/current-system/sw/bin/qdbus org.kde.LogoutPrompt /LogoutPrompt promptReboot
    Icon=system-reboot
    Type=Application
    Categories=System;
    Keywords=reboot;restart;
  '';

  # Custom desktop entry for quick shutdown access in KRunner
  home.file.".local/share/applications/shutdown.desktop".text = ''
    [Desktop Entry]
    Name=Shut Down
    Comment=Shut down the computer
    Exec=/run/current-system/sw/bin/qdbus org.kde.LogoutPrompt /LogoutPrompt promptShutDown
    Icon=system-shutdown
    Type=Application
    Categories=System;
    Keywords=shutdown;power off;halt;
  '';

  # Custom desktop entry for PrimeHack (Metroid Prime Dolphin fork)
  home.file.".local/share/applications/primehack.desktop".text = ''
    [Desktop Entry]
    Name=PrimeHack
    Comment=Metroid Prime emulator (Dolphin fork)
    Exec=/run/current-system/sw/bin/primehack
    Icon=dolphin-emu
    Type=Application
    Categories=Game;Emulator;
    Keywords=metroid;prime;dolphin;emulator;gamecube;wii;
  '';

  home.file.".config/vivaldi/NativeMessagingHosts/org.kde.plasma.browser_integration.json".text =
    builtins.toJSON
      {
        name = "org.kde.plasma.browser_integration";
        description = "Native connector for KDE Plasma Browser Integration";
        path = "${pkgs.kdePackages.plasma-browser-integration}/bin/plasma-browser-integration-host";
        type = "stdio";
        allowed_origins = [ "chrome-extension://cimiefiiaegbelhefglklhhakcgmhkai/" ];
      };

  home.file.".local/share/kwin/scripts/movewindownoswitch/metadata.json".text = builtins.toJSON {
    KPackageStructure = "KWin/Script";
    "X-Plasma-API" = "javascript";
    "X-Plasma-MainScript" = "code/main.js";
    KPlugin = {
      Name = "Move Window Without Switching";
      Description = "Move windows between desktops without switching desktop";
      Icon = "preferences-system-windows-move";
      Id = "movewindownoswitch";
    };
  };

  home.file.".local/share/kwin/scripts/movewindownoswitch/contents/code/main.js".text = ''
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
  '';
}
