{ username, ... }:
{
  nix.enable = false;

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  system.primaryUser = username;
  programs.fish.enable = true;
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
      "helium-browser"
      "raycast"
      "vivaldi"
    ];
  };
}
