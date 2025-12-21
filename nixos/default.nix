{
  config,
  pkgs,
  hostname,
  ghostty,
  ...
}:

{
  imports = [
    ./${hostname}
    ./plasma.nix
  ];

  nix = {
    settings = {
      trusted-users = [ "@wheel" ];
      substituters = [
        "https://ghostty.cachix.org"
      ];
      trusted-public-keys = [
        "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
      ];
    };
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
      netrc-file = /home/jason/.config/nix/netrc
    '';
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  services.xserver.enable = true;

  networking.networkmanager.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Hack to power on bluetooth adapter on boot
  systemd.services.bluetooth-power-on = {
    description = "Power on bluetooth adapter";
    after = [ "bluetooth.service" ];
    wants = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = false;
      TimeoutStartSec = "120s";
      ExecStart = "${pkgs.bash}/bin/bash -c 'while [ $(${pkgs.systemd}/bin/journalctl -k -b | ${pkgs.gnugrep}/bin/grep -c \"hci0: Device setup\") -lt 2 ]; do ${pkgs.coreutils}/bin/sleep 2; done; ${pkgs.coreutils}/bin/sleep 2; ${pkgs.bluez}/bin/bluetoothctl power on'";
    };
  };

  time.timeZone = "America/New_York";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.fish.enable = true;

  programs.nix-ld.enable = true;

  programs.ssh.startAgent = true;

  users.users.jason = {
    isNormalUser = true;
    description = "Jason";
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  nixpkgs.config.allowUnfree = true;

  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    config.common.default = [ "kde" ];
  };

  networking.firewall.allowedTCPPorts = [
    3000
    5432 # PostgreSQL
    5434 # PostgreSQL
    8081
    8384 # Syncthing web UI
    9094
    19000 # React Native Metro bundler
    19001 # React Native packager
    22000 # Syncthing
  ];

  networking.firewall.allowedUDPPorts = [
    22000 # Syncthing
    21027 # Syncthing
  ];

  networking.extraHosts = ''
    127.0.0.1 localhost.com
    127.0.0.1 api.localhost.com
    127.0.0.1 assets.localhost.com
    127.0.0.1 classroom.localhost.com
    127.0.0.1 school.localhost.com
    127.0.0.1 student.localhost.com
    127.0.0.1 console.localhost.com
    127.0.0.1 faktory.localhost.com
    127.0.0.1 tts.localhost.com
    127.0.0.1 sso.localhost.com
  '';

  virtualisation.docker = {
    enable = true;
    package = pkgs.docker;
  };

  environment.systemPackages = with pkgs; [
    home-manager
    cachix
    ghostty.packages.${system}.default
    nodejs
    dolphin-emu
    usbutils
    appimage-run
  ];

  services.syncthing = {
    enable = true;
    user = "jason";
    dataDir = "/home/jason/.local/share/syncthing";
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = {
        "desktop" = {
          id = "6VW6XO3-4NY4ING-SUYWZIO-ULIVMZ7-ROFUS2F-6ZJE6ZX-X4KXIYY-Z6I43QC";
        };
        "laptop" = {
          id = "E44XEWP-DHRVVXR-3WSATAY-XL2G6L6-XAQIXEI-VPNNDPM-66CZKN3-ALG3XQA";
        };
      };
      folders = {
        "dolphin-gc" = {
          path = "/home/jason/.local/share/dolphin-emu/GC";
          devices = [
            "desktop"
            "laptop"
          ];
        };
        "dolphin-wii" = {
          path = "/home/jason/.local/share/dolphin-emu/Wii";
          devices = [
            "desktop"
            "laptop"
          ];
        };
        "dolphin-states" = {
          path = "/home/jason/.local/share/dolphin-emu/StateSaves";
          devices = [
            "desktop"
            "laptop"
          ];
        };
        "dolphin-profiles" = {
          path = "/home/jason/.config/dolphin-emu/Profiles";
          devices = [
            "desktop"
            "laptop"
          ];
        };
        "dolphin-roms" = {
          path = "/home/jason/Documents/dolphin";
          devices = [
            "desktop"
            "laptop"
          ];
        };
      };
    };
  };

  # Dolphin emulator: udev rules + GCC adapter overclocking
  services.udev.packages = [ pkgs.dolphin-emu ];
  boot.extraModulePackages = [ config.boot.kernelPackages.gcadapter-oc-kmod ];
  boot.kernelModules = [ "gcadapter_oc" ];

  environment.sessionVariables = {
    NPM_CONFIG_PREFIX = "/home/jason/.npm-packages";
  };

  environment.shellInit = ''
    export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
  '';

  system.stateVersion = "25.05";
}
