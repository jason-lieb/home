{ config, pkgs, pkgs-unstable, ... }:

{
  networking.hostName = "chromebook";

  imports = [
    ./configuration.nix
    ./modules/chromebook/hardware-configuration.nix
    ./modules/chromebook/keyd.nix
  ];

  services.xserver.libinput = {
    enable = true;
    touchpad.tapping = true;
  };
}
