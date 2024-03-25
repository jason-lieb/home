{ config, pkgs, ... }:

{
  services.xserver.enable = true;

  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "jason";

  # Configure keymap
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };
}
