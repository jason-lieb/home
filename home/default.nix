{
  pkgs,
  system,
  platform,
  freckle,
  ...
}:

{
  home = {
    username = pkgs.lib.optionalAttrs (platform == "nixos" || platform == "home") "jason";
    homeDirectory = pkgs.lib.optionalAttrs (platform == "nixos" || platform == "home") "/home/jason";
    stateVersion = pkgs.lib.optionalAttrs (platform == "nixos" || platform == "home") "24.05";
  };

  home.sessionVariables.EDITOR = "code";

  targets.genericLinux.enable = if platform == "home" then true else false;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  imports = [
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
      neofetch
      nil
      nixfmt-rfc-style
      obsidian
      ripgrep
      sqlitebrowser
      wget
      wl-clipboard
      yazi
      zellij
      zoxide
    ])
    ++ (
      if platform == "darwin" || platform == "home" then
        with pkgs;
        [
          home-manager
          nixFlakes
        ]
      else
        [ ]
    )
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
      env = import ./env.nix;
      alacritty = import ./alacritty.nix;
      nix-conf = import ./nix-conf.nix;
      nix-cache = import ./nix-cache.nix { inherit env; };
      desktop-apps = import ./desktop-apps.nix { inherit pkgs; };
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
      ++ (if platform == "darwin" || platform == "home" then [ nix-conf ] ++ desktop-apps else [ ])
    );
}
