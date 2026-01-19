{
  pkgs,
  pkgs-unstable,
  hostname,
  ...
}:

let
  env = import ./env.nix;
  isMini = hostname == "mini";
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
    ./plasma.nix
  ];

  services.flatpak = {
    packages = [
      "io.github.am2r_community_developers.AM2RLauncher"
    ];
  };

  home.packages =
    (with pkgs; [
      # Nix
      nixd
      nixfmt-rfc-style

      # Utilities
      awscli2
      bat
      eyedropper
      ffmpeg
      gnumake
      gparted
      htop
      just
      jq
      lazygit
      lf
      lsof
      neofetch
      tokei
      wget
      wl-clipboard
      zoxide

      # Browsers
      brave
      firefox
      google-chrome
      vivaldi

      # Programs
      claude-code
      github-desktop
      mgba
      obsidian
      opencode
    ])
    ++ (with pkgs-unstable; [
      code-cursor
    ]);

  xdg.mimeApps =
    let
      defaultBrowser = if isMini then "brave-browser.desktop" else "vivaldi-stable.desktop";
    in
    {
      enable = true;
      defaultApplications = {
        "application/zip" = "org.kde.dolphin.desktop";
        "application/pdf" = "org.kde.okular.desktop";
        "text/html" = defaultBrowser;
        "video/mp4" = defaultBrowser;
        "x-scheme-handler/http" = defaultBrowser;
        "x-scheme-handler/https" = defaultBrowser;
        "image/jpeg" = "org.kde.gwenview.desktop";
        "image/png" = "org.kde.gwenview.desktop";
      };
    };

  xdg.configFile =
    if isMini then
      {
        "autostart/brave-browser.desktop".source = "${pkgs.brave}/share/applications/brave-browser.desktop";
      }
    else
      {
        "autostart/vivaldi-stable.desktop".source =
          "${pkgs.vivaldi}/share/applications/vivaldi-stable.desktop";
        "autostart/obsidian.desktop".source = "${pkgs.obsidian}/share/applications/obsidian.desktop";
        "autostart/cursor.desktop".source =
          "${pkgs-unstable.code-cursor}/share/applications/cursor.desktop";
      };

  programs.git = {
    enable = true;

    settings = {
      user.name = "Jason Lieb";
      user.email = "Jason.lieb@outlook.com";
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

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "https";
      prompt = "enabled";
    };
  };

  # Sync Cursor settings with VSCode settings using a simple activation script
  home.activation.syncCursorSettings = ''
    # Ensure Cursor User directory exists
    mkdir -p ~/.config/Cursor/User

    # Create symlinks for settings and keybindings if VSCode config exists
    if [ -f ~/.config/Code/User/settings.json ] && [ ! -e ~/.config/Cursor/User/settings.json ]; then
      ln -sf ~/.config/Code/User/settings.json ~/.config/Cursor/User/settings.json
    fi

    if [ -f ~/.config/Code/User/keybindings.json ] && [ ! -e ~/.config/Cursor/User/keybindings.json ]; then
      ln -sf ~/.config/Code/User/keybindings.json ~/.config/Cursor/User/keybindings.json
    fi
  '';

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

          [profile student-journey-dev-01]
          sso_start_url = ${env.REN_SWISS_AWS_SSO_URL}
          sso_region = us-west-2
          sso_account_id = ${env.STUDENT_JOURNEY_AWS_ACCOUNT_ID_DEV}
          sso_role_name = ${env.STUDENT_JOURNEY_AWS_SSO_ROLE_NAME}
          region = us-west-2

          [profile student-journey-prod-01]
          sso_start_url = ${env.REN_SWISS_AWS_SSO_URL}
          sso_region = us-west-2
          sso_account_id = ${env.STUDENT_JOURNEY_AWS_ACCOUNT_ID_PROD}
          sso_role_name = ${env.STUDENT_JOURNEY_AWS_SSO_ROLE_NAME}
          region = us-west-2

          [profile student-journey-stage-01]
          sso_start_url = ${env.REN_SWISS_AWS_SSO_URL}
          sso_region = us-west-2
          sso_account_id = ${env.STUDENT_JOURNEY_AWS_ACCOUNT_ID_STAGE}
          sso_role_name = ${env.STUDENT_JOURNEY_AWS_SSO_ROLE_NAME}
          region = us-west-2
        '';
        ".aws/credentials".text = "";
      };

      claudeConfig = {
        ".claude/settings.json".text = ''
          {
            "awsAuthRefresh": "aws sso login --profile freckle-dev",
            "env": {
              "CLAUDE_CODE_USE_BEDROCK": "1",
              "AWS_REGION": "us-east-1",
              "CLAUDE_CODE_MAX_OUTPUT_TOKENS": "64000",
              "MAX_THINKING_TOKENS": "4096",
              "ANTHROPIC_MODEL": "us.anthropic.claude-sonnet-4-5-20250929-v1:0",
              "ANTHROPIC_DEFAULT_HAIKU_MODEL": "us.anthropic.claude-3-5-haiku-20241022-v1:0",
              "ANTHROPIC_DEFAULT_SONNET_MODEL": "us.anthropic.claude-sonnet-4-5-20250929-v1:0",
              "AWS_PROFILE": "freckle-dev"
            },
            "model": "us.anthropic.claude-sonnet-4-20250514-v1:0",
            "alwaysThinkingEnabled": false
          }
        '';
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

          keybind = ctrl+t=new_tab
          keybind = ctrl+w=close_tab
          keybind = ctrl+tab=next_tab
          keybind = ctrl+shift+tab=previous_tab

          keybind = ctrl+shift+enter=new_split:right
          keybind = ctrl+shift+d=new_split:down
          keybind = ctrl+shift+h=goto_split:left
          keybind = ctrl+shift+l=goto_split:right
          keybind = ctrl+shift+k=goto_split:up
          keybind = ctrl+shift+j=goto_split:down
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
    awsConfig
    // claudeConfig
    // ghosttyConfig
    // gitConfig
    // nixConfig
    // npmConfig
    // stackConfig
    // vscodeSnippets;
}
