{ pkgs, ... }:

{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  services.desktopManager.plasma6.enable = true;

  programs.kdeconnect.enable = true;

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    discover # Software center (flatpak GUI)
    elisa # Music player
    ffmpegthumbs # Video thumbnails
    kate # Advanced text editor
    khelpcenter # Help documentation
    konsole # Terminal emulator
  ];
}
