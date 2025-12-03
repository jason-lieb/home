{ pkgs, ... }:

{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  services.desktopManager.plasma6.enable = true;

  programs.kdeconnect.enable = true;

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    # ark # Archive manager
    # baloo-widgets # File indexing info in Dolphin
    # discover # Software center (flatpak GUI)
    # dolphin-plugins # Extra Dolphin features
    elisa # Music player
    ffmpegthumbs # Video thumbnails
    # gwenview # Image viewer
    # kate # Advanced text editor
    khelpcenter # Help documentation
    konsole # Terminal emulator
    # plasma-browser-integration # Browser integration
    # spectacle # Screenshot tool
    # xwaylandvideobridge # Screen capture for X11 apps
  ];
}
