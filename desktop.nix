{ config, pkgs, pkgs-unstable, ... }: {
  networking.hostName = "desktop";
  imports = [ ./configuration.nix ];
}
