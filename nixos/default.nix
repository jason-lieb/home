{ pkgs, hostname, ... }:

{
  imports = [
    ./${hostname}
    ./gnome.nix
  ];

  nix = {
    settings = {
      trusted-users = [ "@wheel" ];
      substituters = [
        "https://freckle.cachix.org"
        "https://freckle-private.cachix.org"
        "https://yazi.cachix.org"
        "https://cosmic.cachix.org/"
      ];
      trusted-public-keys = [
        "freckle.cachix.org-1:WnI1pZdwLf2vnP9Fx7OGbVSREqqi4HM2OhNjYmZ7odo="
        "freckle-private.cachix.org-1:zbTfpeeq5YBCPOjheu0gLyVPVeM6K2dc1e8ei8fE0AI="
        "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
        "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
      ];

    };
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
      netrc-file = /home/jason/.config/nix/netrc
    '';
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 10d";
    };
  };

  systemd.timers."clear-nix-store" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };

  systemd.services."clear-nix-store" = {
    script = ''
      set -eu
      LOGFILE=/var/log/clear-nix-store.log
      {
      echo "Starting garbage collection: $(date)"
      ${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 7d
      echo "Garbage collection completed: $(date)"
      /run/current-system/bin/switch-to-configuration boot
      echo "Switched to new configuration: $(date)"
      } >> $LOGFILE 2>&1
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.xserver.enable = true;

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  networking.networkmanager.enable = true;

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

  services.printing.enable = true;

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.defaultUserShell = "/run/current-system/sw/bin/fish";

  users.users.jason = {
    isNormalUser = true;
    description = "Jason";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  nixpkgs.config.allowUnfree = true;

  services.flatpak.enable = true;

  services.ollama.enable = true;

  # virtualisation.oci-containers = {
  #   backend = "docker";

  #   containers = {
  #     open-webui = import ./open-webui.nix;
  #   };
  # };

  environment.systemPackages = with pkgs; [
    home-manager
    cachix
    # open-webui
    # oterm
  ];

  # services.openssh.enable = true;

  system.stateVersion = "24.05";
}
