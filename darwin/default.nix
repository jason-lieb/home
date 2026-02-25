{ pkgs, username, ... }:
{
  nix.enable = false;

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    shell = pkgs.fish;
  };

  system.primaryUser = username;
  programs.fish.enable = true;
  system.stateVersion = 6;

  security.pam.services.sudo_local.touchIdAuth = true;

  # system.defaults = {
  #   dock = {
  #     autohide = true;
  #     autohide-delay = 0.0;         # remove delay before dock shows
  #     autohide-time-modifier = 0.2;  # animation speed
  #     mru-spaces = false;            # don't rearrange Spaces based on most recent use
  #     show-recents = false;
  #     tilesize = 48;
  #     minimize-to-application = true;
  #     persistent-apps = [ ];         # clear default dock icons (rebuild adds them back)
  #   };
  #
  #   finder = {
  #     AppleShowAllExtensions = true;
  #     AppleShowAllFiles = true;       # show hidden files
  #     FXPreferredViewStyle = "clmv";  # column view (Nlsv=list, icnv=icon, clmv=column, Flwv=gallery)
  #     FXEnableExtensionChangeWarning = false;
  #     ShowPathbar = true;
  #     ShowStatusBar = true;
  #     _FXShowPosixPathInTitle = true; # full path in Finder title bar
  #   };
  #
  #   NSGlobalDomain = {
  #     AppleShowAllExtensions = true;
  #     AppleInterfaceStyle = "Dark";    # dark mode
  #     KeyRepeat = 2;                   # fast key repeat (lower = faster, default 6)
  #     InitialKeyRepeat = 15;           # short delay before repeat (default 25)
  #     NSAutomaticCapitalizationEnabled = false;
  #     NSAutomaticSpellingCorrectionEnabled = false;
  #     NSAutomaticPeriodSubstitutionEnabled = false;
  #     NSAutomaticDashSubstitutionEnabled = false;
  #     NSAutomaticQuoteSubstitutionEnabled = false;
  #     "com.apple.swipescrolldirection" = true; # natural scrolling
  #   };
  #
  #   trackpad = {
  #     Clicking = true;                 # tap to click
  #     TrackpadThreeFingerDrag = true;
  #   };
  #
  #   CustomUserPreferences = {
  #     "com.apple.desktopservices" = {
  #       DSDontWriteNetworkStores = true; # no .DS_Store on network volumes
  #       DSDontWriteUSBStores = true;     # no .DS_Store on USB drives
  #     };
  #   };
  # };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "none";
      upgrade = true;
    };

    brews = [ ];

    # GUI apps on macOS are installed exclusively through casks.
    casks = [
      "ghostty"
      "helium-browser"
      "raycast"
      "vivaldi"
      "zen-browser"
    ];
  };
}
