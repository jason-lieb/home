{ ... }:

{
  networking.hostName = "mini";
  imports = [ ./hardware.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  swapDevices = [{
    device = "/swapfile";
    size = 8 * 1024; # 8GB
  }];
}
