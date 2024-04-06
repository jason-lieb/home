{ config, pkgs, pkgs-unstable, ... }:

{
  networking.hostName = "desktop";
  imports =
    [ ./configuration.nix /etc/nixos/hardware-configuration.nix ];
}
