{
  config,
  pkgs,
  pkgs-unstable,
  claude-code-pkg,
  hostname,
  ...
}:
let
  isMini = hostname == "mini";
in
{
  imports = [
    ./shells.nix
    ./vscode.nix
    ./plasma.nix
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

      eyedropper
      gparted
      wl-clipboard
      brave
      firefox
      google-chrome
      vivaldi
      github-desktop
      mgba
      obsidian
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

  services.flatpak = {
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];
    packages = [
      "io.github.am2r_community_developers.AM2RLauncher"
    ];
    overrides."io.github.am2r_community_developers.AM2RLauncher".Context.filesystems = [
      "/run/udev:ro"
    ];
  };

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

  home.activation.syncCursorSettings = ''
    mkdir -p ~/.config/Cursor/User

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
