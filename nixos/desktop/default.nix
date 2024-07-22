{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:

{
  networking.hostName = "desktop";
  imports = [
    ../configuration.nix
    /etc/nixos/hardware-configuration.nix
  ];

  environment.systemPackages = with pkgs; [ gnomeExtensions.brightness-control-using-ddcutil ];
}
