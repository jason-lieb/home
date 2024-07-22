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
    ./hardware-configuration.nix
  ];
}
