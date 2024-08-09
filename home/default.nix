{
  pkgs,
  config,
  vscode-extensions,
  ...
}:

let
  importWithArgs = file: import file { inherit config pkgs vscode-extensions; };
in
{
  home.username = "jason";
  home.homeDirectory = "/home/jason";
  home.stateVersion = "24.05";

  home.sessionVariables.EDITOR = "code";

  imports = [
    ./fish.nix
    ./git.nix
    (importWithArgs ./vscode.nix)
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
    nil
    nixfmt-rfc-style
    obsidian
    ollama
    python3
    ripgrep
    sqlitebrowser
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
      "application/pdf" = "org.gnome.Evince.desktop";
      "text/html" = "brave-browser.desktop";
      "video/mp4" = "brave-browser.desktop";
      "image/jpeg" = "org.gnome.Loupe.desktop"; # Loupe = Image Viewer
      "image/png" = "org.gnome.Loupe.desktop";
    };
  };

  home.file =
    let
      env = import ./env.nix;
      alacritty = import ./alacritty.nix;
      nix-cache = import ./nix-cache.nix { inherit env; };
      aws = import ./aws.nix;
      aws-credentials = import ./aws-credentials.nix;
      stack = import ./stack.nix;
      autostart = import ./autostart.nix { inherit pkgs; };
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
