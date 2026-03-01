{ ... }:

{
  networking.hostName = "z560";
  imports = [ ./hardware.nix ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };
}
