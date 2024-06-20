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
    ../modules/hardware-configuration.nix
  ];
}
