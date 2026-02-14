{ ... }:
{

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "@admin" ];
  };

  nix.optimise.automatic = true;

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  users.users.jason = {
    name = "jason";
    home = "/Users/jason";
  };

  system.primaryUser = "jason";
  programs.fish.enable = true;
  services.nix-daemon.enable = true;

  system.stateVersion = 6;

  networking.hostName = "work";

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "zap";
      upgrade = true;
    };

    brews = [ ];

    # GUI apps on macOS are installed exclusively through casks.
    casks = [
      "visual-studio-code"
      "ghostty"
      "google-chrome"
      "helium-browser"
      "raycast"
      "vivaldi"
    ];
  };
}
