{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  networking.hostName = "jason";
  time.timeZone = "America/New_York";

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

  environment.systemPackages = with pkgs; [
    home-manager
    cachix
  ];
}
