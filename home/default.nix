{
  pkgs,
  pkgs-unstable,
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
    ./shells.nix
    ./git.nix
    ./neovim.nix
    ./vscode.nix
  ];

  home.packages =
    (with pkgs; [
      brave
      chromium
      gh
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
      obsidian
      sqlitebrowser
      wget
      wl-clipboard
      yazi
      zellij
      zoxide
    ])
    ++ (with pkgs-unstable; [
      code-cursor
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
      awsConfig = {
        ".aws/config".text = ''
          [profile freckle]
          sso_start_url = ${env.AWS_SSO_URL}
          sso_region = us-east-1
          sso_account_id = ${env.AWS_ACCOUNT_ID_PROD}
          sso_role_name = Freckle-Prod-Engineers
          region = us-east-1

          [profile freckle-dev]
          sso_start_url = ${env.AWS_SSO_URL}
          sso_region = us-east-1
          sso_account_id = ${env.AWS_ACCOUNT_ID_DEV}
          sso_role_name = Freckle-Dev-Engineers
          region = us-east-1

        '';
        ".aws/credentials".text = "";
      };

      nixConfig = {
        ".config/nix/netrc".text = "machine freckle-private.cachix.org password ${env.TOKEN}";
        ".config/nix/nix.conf".text = "access-tokens = github.com=${env.GITHUB_TOKEN}";
      };

      stackConfig = {
        ".stack/config.yaml".text = ''
          nix: { enable: false }
          system-ghc: true
          recommend-stack-upgrade: false
          notify-if-nix-on-path: false
          ghc-options:
            "$everything": -fconstraint-solver-iterations=10 -O0 -fobject-code -j +RTS -A64m -n2m -RTS
        '';
      };
    in
    awsConfig // nixConfig // stackConfig;

}
