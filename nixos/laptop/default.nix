{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:

{
  networking.hostName = "laptop";
  imports = [ ./hardware.nix ];
}
