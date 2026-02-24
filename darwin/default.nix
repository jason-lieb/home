{ username, ... }:
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

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  system.primaryUser = username;
  programs.fish.enable = true;
  services.nix-daemon.enable = true;

  system.stateVersion = 6;

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
      "visual-studio-code"
      "ghostty"
      "google-chrome"
      "helium-browser"
      "raycast"
      "vivaldi"
    ];
  };
}
