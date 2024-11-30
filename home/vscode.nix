{
  pkgs,
  pkgs-unstable,
  vscode-extensions,
  ...
}:

{
  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    mutableExtensionsDir = false;
    package = pkgs-unstable.vscode;

    extensions =
      (with vscode-extensions.vscode-marketplace; [
        # asvetliakov.vscode-neovim
        # continue.continue
        esbenp.prettier-vscode
        golang.go
        haskell.haskell
        jkillian.custom-local-formatters
        jnoortheen.nix-ide
        justusadam.language-haskell
        mechatroner.rainbow-csv
        mhutchie.git-graph
        oderwat.indent-rainbow
        pkief.material-icon-theme
        ritwickdey.liveserver
        stylelint.vscode-stylelint
        # supermaven.supermaven
        tomrijndorp.find-it-faster
        # vscodevim.vim
        yoavbls.pretty-ts-errors
      ])
      ++ (with vscode-extensions.vscode-marketplace-release; [
        github.copilot
        github.copilot-chat
      ]);

    userSettings = {
      "diffEditor.maxComputationTime" = 0;
      "editor.accessibilitySupport" = "off";
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "[haskell]" = {
        "editor.defaultFormatter" = "jkillian.custom-local-formatters";
      };
      "[nix]" = {
        "editor.defaultFormatter" = "jkillian.custom-local-formatters";
      };
      "editor.formatOnPaste" = true;
      "editor.formatOnSave" = true;
      "[markdown]" = {
        "editor.formatOnSave" = false;
      };
      "[yaml]" = {
        "editor.formatOnSave" = false;
      };
      "[yml]" = {
        "editor.formatOnSave" = false;
      };
      "editor.minimap.enabled" = false;
      "editor.parameterHints.enabled" = false;
      "editor.tabSize" = 2;
      "editor.largeFileOptimizations" = false;
      "explorer.confirmDelete" = false;
      "explorer.confirmDragAndDrop" = false;
      "customLocalFormatters.formatters" = [
        {
          command = "fourmolu --stdin-input-file \${file}";
          languages = [ "haskell" ];
        }
        {
          command = "nixfmt";
          languages = [ "nix" ];
        }
      ];
      "files.insertFinalNewline" = true;
      "files.trimTrailingWhitespace" = true;
      "go.alternateTools" = {
        "go" = "${pkgs.go}/bin/go";
      };
      "[go]" = {
        "editor.defaultFormatter" = "golang.go";
      };
      "haskell.checkProject" = false;
      "haskell.plugin.hlint.diagnosticsOn" = true;
      "haskell.trace.client" = "debug";
      "haskell.trace.server" = "messages";
      "haskell.manageHLS" = "PATH";
      "indentRainbow.indicatorStyle" = "light";
      "indentRainbow.lightIndicatorStyleLineWidth" = 4;
      "javascript.updateImportsOnFileMove.enabled" = "always";
      "javascript.validate.enable" = false;
      "liveServer.settings.donotShowInfoMsg" = true;
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nixd";
      # "nixpkgs.expr" = "import (builtins.getFlake \"/home/jason/home").inputs.nixpkgs { }";
      # "options" = {
      #   "nixos.expr" = "builtins.getFlake \"/home/jason/home".nixosConfigurations.desktop.options";
      #   "home_manager.expr" = "builtins.getFlake \"/home/jason/home".homeConfigurations.desktop.options";
      # }
      "prettier.enable" = true;
      "prettier.singleQuote" = true;
      "security.workspace.trust.untrustedFiles" = "open";
      "window.openFoldersInNewWindow" = "off";
      "workbench.colorTheme" = "Default Dark+";
      "workbench.iconTheme" = "material-icon-theme";
      "workbench.startupEditor" = "none";
      "workbench.panel.defaultLocation" = "right";
      "git.openRepositoryInParentFolders" = "never";
      "diffEditor.ignoreTrimWhitespace" = false;
      "stylelint.validate" = [ "scss" ];
      "typescript.updateImportsOnFileMove.enabled" = "always";
      "update.mode" = "none";
      "window.menuBarVisibility" = "toggle";
      "extensions.ignoreRecommendations" = true;
      # "vscode-neovim.neovimExecutablePaths.linux" = "${pkgs.neovim}/bin/nvim";
      # "vim.easymotion" = true;
      # "vim.incsearch" = true;
      # "vim.useSystemClipboard" = true;
      # "vim.useCtrlKeys" = true;
      # "vim.hlsearch" = true;
      # "vim.insertModeKeyBindings" = [
      #   {
      #     "before" = [
      #       "j"
      #       "j"
      #     ];
      #     "after" = [ "<Esc>" ];
      #   }
      # ];
      # "vim.normalModeKeyBindingsNonRecursive" = [
      #   {
      #     "before" = [
      #       "<leader>"
      #       "d"
      #     ];
      #     "after" = [
      #       "d"
      #       "d"
      #     ];
      #   }
      #   {
      #     "before" = [ "<C-n>" ];
      #     "commands" = [ "=nohl" ];
      #   }
      #   {
      #     "before" = [ "K" ];
      #     "commands" = [ "lineBreakInsert" ];
      #     "silent" = true;
      #   }
      # ];
      # "vim.leader" = "<space>";

      # Prevent vim from handling certain keybindings
      # "vim.handleKeys" = {
      #   "<C-a>" = false;
      #   "<C-f>" = false;
      # };
      # "extensions.experimental.affinity" = {
      #   "vscodevim.vim" = 1;
      # };

      #     "vim.easymotion": true,
      # "vim.incsearch": true,
      # "vim.useSystemClipboard": true,
      # "vim.hlsearch": true,
      # "vim.insertModeKeyBindings": [
      #   {
      #     "before": ["j", "j"],
      #     "after": ["<Esc>"]
      #   }
      # ],
      # "vim.leader": "<space>",
      # "vim.handleKeys": {
      #   "<C-a>": false,
      #   "<C-f>": false
      # },
      # "vim.normalModeKeyBindingsNonRecursive": [
      #   {
      #     "before": [":"],
      #     "commands": ["workbench.action.showCommands"]
      #   }
      # ],
      # "vim.visualModeKeyBindingsNonRecursive": [
      #   {
      #     "before": [">"],
      #     "commands": ["editor.action.indentLines"]
      #   },
      #   {
      #     "before": ["<"],
      #     "commands": ["editor.action.outdentLines"]
      #   },
      #   {
      #     "before": ["p"],
      #     "after": ["p", "g", "v", "y"]
      #   }
      # ],
      # "vim.statusBarColorControl": true,
      # "vim.statusBarColors.normal": ["#8FBCBB", "#000"],
      # "vim.statusBarColors.insert": ["#BF616A", "#000"],
      # "vim.statusBarColors.visual": ["#B48EAD", "#000"],
      # "vim.statusBarColors.visualline": ["#B48EAD", "#000"],
      # "vim.statusBarColors.visualblock": ["#A3BE8C", "#000"],
      # "vim.statusBarColors.replace": "#D08770",
      # "vim.statusBarColors.commandlineinprogress": "#007ACC",
      # "vim.statusBarColors.searchinprogressmode": "#007ACC",
      # "vim.statusBarColors.easymotionmode": "#007ACC",
      # "vim.statusBarColors.easymotioninputmode": "#007ACC",
      # "vim.statusBarColors.surroundinputmode": "#007ACC",
      # "workbench.colorCustomizations": {
      #   "statusBar.background": "#B48EAD",
      #   "statusBar.noFolderBackground": "#B48EAD",
      #   "statusBar.debuggingBackground": "#B48EAD",
      #   "statusBar.foreground": "#000"
      # }
    };
    keybindings = [
      {
        key = "shift+alt+down";
        command = "-editor.action.insertCursorBelow";
        when = "editorTextFocus";
      }
      {
        key = "shift+alt+up";
        command = "-notebook.cell.copyUp";
        when = "notebookEditorFocused && !inputFocus";
      }
      {
        key = "shift+alt+down";
        command = "-notebook.cell.copyDown";
        when = "notebookEditorFocused && !inputFocus";
      }
      {
        key = "shift+alt+down";
        command = "editor.action.copyLinesDownAction";
        when = "editorTextFocus && !editorReadonly";
      }
      {
        key = "ctrl+shift+alt+down";
        command = "-editor.action.copyLinesDownAction";
        when = "editorTextFocus && !editorReadonly";
      }
      {
        key = "shift+alt+up";
        command = "-editor.action.insertCursorAbove";
        when = "editorTextFocus";
      }
      {
        key = "shift+alt+up";
        command = "editor.action.copyLinesUpAction";
        when = "editorTextFocus && !editorReadonly";
      }
      {
        key = "ctrl+shift+alt+up";
        command = "-editor.action.copyLinesUpAction";
        when = "editorTextFocus && !editorReadonly";
      }
    ];
  };
}
