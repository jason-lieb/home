{
  config,
  pkgs,
  hostname,
  ghostty,
  ...
}:

let
  devices = [
    "desktop"
    "laptop"
    "mini"
  ];
in
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

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
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
    ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default
    nodejs
    dolphin-emu
    # PrimeHack with separate user directory (portable mode)
    (writeShellScriptBin "primehack" ''
      exec ${dolphin-emu-primehack}/bin/dolphin-emu-primehack -u "$HOME/.local/share/primehack" "$@"
    '')
    usbutils
  ];

  programs.appimage.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    extraPackages = with pkgs; [
      pkgsi686Linux.gperftools
    ];
  };

  services.syncthing = {
    enable = true;
    user = "jason";
    # Need to run the following command to get the device ID because of the data dir:
    # syncthing --home=/home/jason/.local/share/syncthing/.config/syncthing device-id
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
        "mini" = {
          id = "ZGTQSNB-CS4454Y-THQKHL3-FNZWSLT-62GC7PG-SR6C4W4-AUFD3P2-3D2AFAA";
        };
      };
      folders = {
        "dolphin-gc" = {
          path = "/home/jason/.local/share/dolphin-emu/GC";
          inherit devices;
        };
        "dolphin-wii" = {
          path = "/home/jason/.local/share/dolphin-emu/Wii";
          inherit devices;
        };
        "dolphin-profiles" = {
          path = "/home/jason/.config/dolphin-emu/Profiles";
          inherit devices;
        };
        "dolphin-roms" = {
          path = "/home/jason/Documents/dolphin";
          inherit devices;
        };
        "mgba-roms" = {
          path = "/home/jason/Documents/mgba";
          inherit devices;
        };
        "primehack-gc" = {
          path = "/home/jason/.local/share/primehack/GC";
          inherit devices;
        };
        "primehack-wii" = {
          path = "/home/jason/.local/share/primehack/Wii";
          inherit devices;
        };
        "primehack-profiles" = {
          path = "/home/jason/.local/share/primehack/Config/Profiles";
          inherit devices;
        };
        "am2r" = {
          path = "/home/jason/Documents/am2r";
          inherit devices;
        };
      };
    };
  };

  # Dolphin emulator: udev rules + GCC adapter overclocking
  services.udev.packages = with pkgs; [
    dolphin-emu
    dolphin-emu-primehack
  ];
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
