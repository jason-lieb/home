{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:

{
  networking.hostName = "laptop";
  imports = [
    ../configuration.nix
    ./hardware-configuration.nix
  ];
}
