{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:

{
  networking.hostName = "chromebook";

  imports = [
    ../configuration.nix
    ./hardware-configuration.nix
    ./keyd.nix
  ];

  # boot = lib.mkIf config.services.tlp.enable {
  #   kernelModules = [ "acpi_call" ];
  #   extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];
  # };
  # environment.systemPackages = [
  #   (import ./audio.nix { inherit pkgs; })
  #   pkgs.sof-firmware
  # ];

  services.libinput = {
    enable = true;
    touchpad.tapping = true;
  };
}
