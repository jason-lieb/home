{
  pkgs,
  pkgs-unstable,
  system,
  freckle,
  ...
}:

let
  env = import ./env.nix;
in
{
  home = {
    username = "jason";
    homeDirectory = "/home/jason";
    stateVersion = "24.05";
  };

  home.sessionVariables.EDITOR = "code";

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  imports = [
    ./bash.nix
    ./fish.nix
    ./git.nix
    ./neovim.nix
    ./vscode.nix
  ];

  home.packages =
    (with pkgs; [
      alacritty
      bat
      brave
      chromium
      gh
      github-copilot-cli
      htop
      just
      jq
      gnumake
      gparted
      lf
      lsof
      neofetch
      nixd
      nixfmt-rfc-style
      # nodePackages.prettier
      obsidian
      ripgrep
      sqlitebrowser
      wget
      wl-clipboard
      yazi
      zellij
      zoxide
    ])
    ++ (with pkgs-unstable; [ code-cursor ])
    ++ (with freckle.packages.${system}; [
      prettier-default
      fourmolu-0-13-x
    ])
    ++ (with freckle.lib.${system}; [
      (haskellBundle {
        ghcVersion = "ghc-9-2-8";
        enableHLS = true;
      })
    ]);

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
      alacritty = import ./alacritty.nix;
      aws = import ./aws.nix { inherit env; };
      aws-credentials = import ./aws-credentials.nix;
      nix-cache = import ./nix-cache.nix { inherit env; };
      nix-conf = import ./nix-conf.nix { inherit env; };
      stack = import ./stack.nix;
      autostart = import ./autostart.nix { inherit pkgs; };
    in
    builtins.listToAttrs (
      [
        alacritty
        aws
        aws-credentials
        nix-cache
        nix-conf
        stack
      ]
      ++ autostart
    );
}
