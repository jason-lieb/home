{ config, pkgs, pkgs-unstable, ... }:

{
  imports =
    # [ inputs.freckle.nixosModules.docker-for-local-dev ./modules/gnome.nix ];
    [ ./modules/gnome.nix ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.xserver = {
    enable = true;
    displayManager.autoLogin = {
      enable = true;
      user = "jason";
    };

    # Configure keymap
    layout = "us";
    xkbVariant = "";
  };

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
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
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };

  security.sudo.wheelNeedsPassword = false;

  nixpkgs.config.allowUnfree = true;

  services.flatpak.enable = true;

  environment.systemPackages = (with pkgs; [
    home-manager
    alacritty
    bat
    chromium
    firefox
    docker
    fish
    gh
    git
    github-copilot-cli
    htop
    gnumake
    neofetch
    neovim
    nixfmt
    python3
    ripgrep
    sof-firmware
    wget
    zoxide
  ])

    ++

    (with pkgs-unstable; [ brave obsidian vscode ]);

  nixpkgs.config.permittedInsecurePackages = [ "electron-25.9.0" ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # services.openssh.enable = true;

  system.stateVersion = "23.11";
}
