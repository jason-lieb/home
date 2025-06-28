{
  pkgs,
  hostname,
  ghostty,
  ...
}:

{
  imports = [
    ./${hostname}
    ./gnome.nix
  ];

  nix = {
    settings.trusted-users = [ "@wheel" ];
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

  networking.firewall.allowedTCPPorts = [
    3000
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
  ];

  environment.sessionVariables = {
    NPM_CONFIG_PREFIX = "/home/jason/.npm-packages";
  };

  environment.shellInit = ''
    export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
  '';

  system.stateVersion = "25.05";
}
