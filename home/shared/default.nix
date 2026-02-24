{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  claude-code,
  system,
  username,
  isDarwin,
  ...
}:
let
  env = import ../env.nix { homeDir = config.home.homeDirectory; };
in
{
  imports = [
    ./shells.nix
  ]
  ++ lib.optionals (!isDarwin) [
    ./vscode.nix
  ];

  home = {
    inherit username;
    homeDirectory = if isDarwin then "/Users/${username}" else "/home/${username}";
    stateVersion = "25.05";
  };

  home.sessionVariables.EDITOR = "code";

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    silent = true;
  };

  home.packages =
    (with pkgs; [
      nixd
      nixfmt-rfc-style
      awscli2
      bat
      ffmpeg
      gnumake
      htop
      just
      jq
      lazygit
      lf
      lsof
      tokei
      wget
      zoxide
      opencode
    ])
    ++ [
      claude-code.packages.${system}.default
    ]
    ++ lib.optionals (!isDarwin) (
      with pkgs;
      [
        (retroarch.withCores (
          cores: with cores; [
            bsnes-hd
          ]
        ))
      ]
    )
    ++ lib.optionals (!isDarwin) (with pkgs-unstable; [ code-cursor ]);

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
              "ANTHROPIC_MODEL": "us.anthropic.claude-opus-4-5-20251101-v1:0",
              "ANTHROPIC_DEFAULT_HAIKU_MODEL": "us.anthropic.claude-3-5-haiku-20241022-v1:0",
              "AWS_PROFILE": "freckle-dev"
            },
            "model": "us.anthropic.claude-sonnet-4-20250514-v1:0",
            "alwaysThinkingEnabled": false,
            "statusLine": {"type": "command", "command": "npx ccstatusline@latest"}
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
        ".npmrc".text = "prefix=${config.home.homeDirectory}/.npm-packages";
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

      cursorConfigDir =
        if isDarwin then "Library/Application Support/Cursor" else ".config/Cursor";
      codeConfigDir =
        if isDarwin then "Library/Application Support/Code" else ".config/Code";

      vscodeSnippets = {
        "${cursorConfigDir}/User/snippets/typescript.json".text = snippets;
        "${cursorConfigDir}/User/snippets/typescriptreact.json".text = snippets;
        "${cursorConfigDir}/User/snippets/javascript.json".text = snippets;
        "${cursorConfigDir}/User/snippets/javascriptreact.json".text = snippets;

        "${codeConfigDir}/User/snippets/typescript.json".text = snippets;
        "${codeConfigDir}/User/snippets/typescriptreact.json".text = snippets;
        "${codeConfigDir}/User/snippets/javascript.json".text = snippets;
        "${codeConfigDir}/User/snippets/javascriptreact.json".text = snippets;
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
