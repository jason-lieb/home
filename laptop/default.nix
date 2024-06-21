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
    ../common/configuration.nix
    ./hardware-configuration.nix
  ];
}
