{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:

{
  networking.hostName = "desktop";
  imports = [ ./hardware.nix ];
}
