{ config, pkgs, pkgs-unstable, ... }: {
  networking.hostName = "chromebook";
  imports = [ ./configuration.nix ];
}
