{ config, pkgs, pkgs-unstable, ... }:

{
  networking.hostName = "chromebook";

  imports = [
    ../common/configuration.nix
    ./modules/hardware-configuration.nix
    ./modules/keyd.nix
  ];

  services.xserver.libinput = {
    enable = true;
    touchpad.tapping = true;
  };
}
