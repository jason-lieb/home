{ config, pkgs, pkgs-unstable, inputs, ... }:

{
  imports = [ ./modules/gnome.nix ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
      auto-optimise-store = true
      netrc-file = /home/jason/.config/nix/netrc
    '';
    settings = {
      trusted-users = [ "@wheel" ];
      max-jobs = 8;
      build-cores = 0;
      substituters =
        [ "https://freckle.cachix.org" "https://freckle-private.cachix.org" ];
      trusted-public-keys = [
        "freckle.cachix.org-1:WnI1pZdwLf2vnP9Fx7OGbVSREqqi4HM2OhNjYmZ7odo="
        "freckle-private.cachix.org-1:zbTfpeeq5YBCPOjheu0gLyVPVeM6K2dc1e8ei8fE0AI="
      ];
    };
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

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [ "en_US.UTF-8/UTF-8" ];
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
    bat
    cachix
    chromium
    firefox
    fish
    gh
    git
    github-copilot-cli
    helix
    htop
    gnumake
    lf
    neofetch
    neovim
    nil
    nixfmt
    ollama
    python3
    ripgrep
    sof-firmware
    vscode
    wget
    zoxide
    # Language servers for Helix
    nodePackages.bash-language-server
    dockerfile-language-server-nodejs
    gopls
    haskell-language-server
    nodePackages.typescript-language-server
    yaml-language-server
  ]) ++ (with pkgs-unstable; [ alacritty brave obsidian ]);

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
