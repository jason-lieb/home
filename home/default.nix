{ pkgs, pkgs-unstable, ... }:

let
  env = import ./env.nix;
in
{
  home = {
    username = "jason";
    homeDirectory = "/home/jason";
    stateVersion = "25.05";
  };

  home.sessionVariables.EDITOR = "code";

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    silent = true;
  };

  imports = [
    ./shells.nix
    ./vscode.nix
  ];

  home.packages =
    (with pkgs; [
      bat
      brave
      claude-code
      firefox
      google-chrome
      gh
      htop
      just
      jq
      github-desktop
      gnumake
      gparted
      lf
      lsof
      neofetch
      nixd
      nixfmt-rfc-style
      obsidian
      wget
      wl-clipboard
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

  programs.git = {
    enable = true;

    userName = "Jason Lieb";
    userEmail = "Jason.lieb@outlook.com";

    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "code --wait";
      core.excludesFile = "~/.gitignore";
      fetch.prune = true;
      merge.ff = "only";
      #merge.tool = "nvimdiff";
      pull.ff = "only";
      pull.autostash = true;
      push.default = "current";
      push.autoSetupRemote = true;
      rebase.autoSquash = true;
      rebase.autoStash = true;
      rebase.stat = true;
      rerere.enabled = true;
      advice.skippedCherryPicks = false;
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
          sso_role_name = ${env.AWS_SSO_ROLE_NAME_PROD}
          region = us-east-1

          [profile freckle-dev]
          sso_start_url = ${env.AWS_SSO_URL}
          sso_region = us-east-1
          sso_account_id = ${env.AWS_ACCOUNT_ID_DEV}
          sso_role_name = ${env.AWS_SSO_ROLE_NAME_DEV}
          region = us-east-1

        '';
        ".aws/credentials".text = "";
      };

      ghosttyConfig = {
        ".config/ghostty/config".text = ''
          theme = Bright Lights
          font-feature = -calt
          font-feature = -liga
          font-feature = -dlig

          keybind = ctrl+c=copy_to_clipboard
          keybind = ctrl+shift+c=text:\x03
          keybind = ctrl+v=paste_from_clipboard
        '';
      };

      gitConfig = {
        ".gitignore".text = ''
          .direnv
        '';
      };

      nixConfig = {
        ".config/nix/netrc".text = "machine freckle-private.cachix.org password ${env.TOKEN}";
        ".config/nix/nix.conf".text = "download-buffer-size = 2048M";
      };

      npmConfig = {
        ".npmrc".text = "prefix=/home/jason/.npm-packages";
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

      snippets = ''
        {
          "console.log": {
            "prefix": "cl",
            "body": "console.log($1)$0",
            "description": "Console log"
          }
        }
      '';

      vscodeSnippets = {
        ".config/Cursor/User/snippets/typescript.json".text = snippets;
        ".config/Cursor/User/snippets/typescriptreact.json".text = snippets;
        ".config/Cursor/User/snippets/javascript.json".text = snippets;
        ".config/Cursor/User/snippets/javascriptreact.json".text = snippets;

        ".config/Code/User/snippets/typescript.json".text = snippets;
        ".config/Code/User/snippets/typescriptreact.json".text = snippets;
        ".config/Code/User/snippets/javascript.json".text = snippets;
        ".config/Code/User/snippets/javascriptreact.json".text = snippets;
      };
    in
    awsConfig // ghosttyConfig // gitConfig // nixConfig // npmConfig // stackConfig // vscodeSnippets;
}
