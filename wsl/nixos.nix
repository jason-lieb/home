{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  networking.hostName = "wsl";
  time.timeZone = "America/New_York";
  #nix = {
  #  settings = {
  #    trusted-users = ["jason"];
  #  };
  #  extraOptions = ''experimental-features = flakes nix-command'';
  #};

  #users.defaultUserShell = "/run/current-system/sw/bin/fish";
  users.users.nixos = {
    isNormalUser = true;
    description = "nixos";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
  };

  environment.systemPackages = with pkgs; [
    vscode
    git
    fish
    home-manager
   # cachix
  ];
}
