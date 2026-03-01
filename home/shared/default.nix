{
  config,
  pkgs,
  pkgs-unstable,
  claude-code-pkg,
  ...
}:
{
  imports = [
    ./shells.nix
    ./vscode.nix
  ];

  home.stateVersion = "25.05";

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

      nodejs
      pnpm
      bun
    ])
    ++ [
      claude-code-pkg
    ]
    ++ (with pkgs; [
      (retroarch.withCores (
        cores: with cores; [
          bsnes-hd
        ]
      ))
    ])
    ++ (with pkgs-unstable; [ code-cursor ]);

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
        ".aws/config".text = "";
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


      snippetText = ''
        {
          "console.log": {
            "prefix": "cl",
            "body": "console.log($1)$0",
            "description": "Console log"
          }
        }
      '';

      mkSnippets =
        dir:
        builtins.listToAttrs (
          map (lang: {
            name = "${dir}/User/snippets/${lang}.json";
            value.text = snippetText;
          }) [
            "typescript"
            "typescriptreact"
            "javascript"
            "javascriptreact"
          ]
        );
    in
    awsConfig
    // ghosttyConfig
    // gitConfig
    // nixConfig
    // npmConfig
    // stackConfig
    // mkSnippets ".config/Cursor"
    // mkSnippets ".config/Code";
}
