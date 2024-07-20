{ pkgs, pkgs-unstable, ... }:

{
  home.username = "jason";
  home.homeDirectory = "/home/jason";
  home.stateVersion = "24.05";

  home.sessionVariables.EDITOR = "code";

  imports = [
    ./modules/firefox.nix
    ./modules/fish.nix
    ./modules/git.nix
    ./modules/vscode.nix
  ];

  home.packages = with pkgs; [
    alacritty
    bat
    brave
    chromium
    gh
    github-copilot-cli
    htop
    gnumake
    gparted
    lf
    neofetch
    neovim
    nil
    nixfmt-rfc-style
    obsidian
    ollama
    python3
    ripgrep
    wget
    wl-clipboard
    yazi
    zellij
    zoxide
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/zip" = "org.gnome.Nautilus.desktop";
      "text/html" = "brave-browser.desktop";
      "video/mp4" = "brave-browser.desktop";
      "image/jpeg" = "org.gnome.Loupe.desktop"; # Loupe = Image Viewer
      "image/png" = "org.gnome.Loupe.desktop";
    };
  };

  home.file =
    let
      env = import ./modules/env.nix;
      alacritty = import ./modules/alacritty.nix;
      nix-cache = import ./modules/nix-cache.nix { inherit env; };
      aws = import ./modules/aws.nix;
      aws-credentials = import ./modules/aws-credentials.nix;
      stack = import ./modules/stack.nix;
      autostart = import ./modules/autostart.nix { inherit pkgs pkgs-unstable; };
    in
    builtins.listToAttrs (
      [
        alacritty
        nix-cache
        aws
        aws-credentials
        stack
      ]
      ++ autostart
    );
}
