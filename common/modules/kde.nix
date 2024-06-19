{ config, pkgs, ... }:

{
  services.xserver = {
    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true;
  };

  environment.systemPackages = with pkgs; [

  ];

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    # plasma-browser-integration
    konsole
    # oxygen
  ];
}
