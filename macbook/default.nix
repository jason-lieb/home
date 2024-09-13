{ self, config, ... }:

{
  users.users.davish = {
    name = "jason.lieb";
    home = "/Users/jason.lieb";
  };

  services.nix-daemon.enable = true;

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = 4;
  nixpkgs.hostPlatform = "aarch64-darwin";

  homebrew = {
    enable = true;
    caskArgs.no_quarantine = true;
    onActivation = {
      cleanup = "zap";
      upgrade = true;
    };
    taps = builtins.attrNames config.nix-homebrew.taps;
    casks = [ "chatgpt" ];
    masApps."Copilot" = 1447330651;
  };

  security.pam.enableSudoTouchIdAuth = true;

  # system.defaults = {
  #   ".GlobalPreferences"."com.apple.mouse.scaling" = 1.5;
  #   LaunchServices.LSQuarantine = false;
  #   NSGlobalDomain = {
  #     AppleScrollerPagingBehavior = true; # Jump to spot on scroll bar when clicked
  #     NSAutomaticCapitalizationEnabled = false;
  #     NSAutomaticDashSubstitutionEnabled = false;
  #     NSAutomaticPeriodSubstitutionEnabled = false;
  #     NSAutomaticQuoteSubstitutionEnabled = false; # Disable smart quoting
  #     NSAutomaticSpellingCorrectionEnabled = false;
  #     "com.apple.springing.enabled" = true;
  #     "com.apple.springing.delay" = 0.5;
  #     # "com.apple.trackpad.forceClick" = 1; # TODO
  #     "com.apple.trackpad.scaling" = 1.0;

  #     # Always use expanded save panel
  #     NSNavPanelExpandedStateForSaveMode = true;
  #     NSNavPanelExpandedStateForSaveMode2 = true;

  #     # Quickly repeat keys when held
  #     InitialKeyRepeat = 15;
  #     KeyRepeat = 2;
  #   };
  #   dock = {
  #     appswitcher-all-displays = false;
  #     autohide = false;
  #     mineffect = "scale";
  #     minimize-to-application = false;
  #     mru-spaces = false;
  #     orientation = "bottom";
  #     persistent-apps = [
  #       "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"
  #       "/System/Applications/Mail.app"
  #       "/Applications/Nova.app"
  #       "/Applications/Prompt.app"
  #       "/Applications/Reeder.app"
  #       "/Applications/Omnivore.app"
  #       "/System/Applications/Music.app"
  #       "/System/Applications/Calendar.app"
  #       "/Applications/Things3.app"
  #       "/System/Applications/Notes.app"
  #       "/System/Applications/Messages.app"
  #       "/Applications/Slack.app"
  #       "/Applications/GitHub Desktop.app"
  #     ];
  #     show-process-indicators = false;
  #     showhidden = false;
  #     show-recents = false;
  #     static-only = false;
  #     magnification = true;

  #     # Disable hot corners
  #     wvous-tl-corner = 1;
  #     wvous-bl-corner = 1;
  #     wvous-tr-corner = 1;
  #     wvous-br-corner = 1;
  #   };
  #   finder = {
  #     AppleShowAllFiles = false;
  #     ShowStatusBar = false;
  #     ShowPathbar = false;
  #     FXDefaultSearchScope = "SCcf"; # Search current folder first when searching
  #     FXPreferredViewStyle = "Nlsv"; # Prefer list view
  #     AppleShowAllExtensions = true;
  #     FXEnableExtensionChangeWarning = false; # Do not warn when changing file extensions
  #   };
  #   menuExtraClock = {
  #     ShowAMPM = true;
  #     ShowDayOfWeek = false;
  #     ShowDate = 0; # Show full date
  #   };
  #   screencapture.location = "~/Downloads";
  #   trackpad = {
  #     Clicking = true; # tap to click
  #     Dragging = true; # tap to drag
  #     TrackpadThreeFingerDrag = true;
  #   };
  # };

  # system.defaults.CustomUserPreferences = {
  #   "com.apple.desktopservices" = {
  #     DSDontWriteNetworkStores = true;
  #   };

  #   "com.pilotmoon.popclip" = {
  #     CombinedItemOrder = [
  #       "openlink"
  #       "search"
  #       "cut"
  #       "copy"
  #       "paste"
  #       "revealfile"
  #       "lookup"
  #       "ext-com.pilotmoon.popclip.extension.parcel"
  #       "openmail"
  #     ];
  #     HasShownWelcome = true;
  #     NMStatusItemHideIcon = true;
  #     "extension#com.pilotmoon.popclip.builtin-search#template" = "https://kagi.com/search?q=***";
  #   };
  # };
}
