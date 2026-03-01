{
  pkgs,
  pkgs-unstable,
  vscode-extensions,
  ...
}:
{
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;
    package = pkgs-unstable.vscode;

    profiles.default = {
      enableUpdateCheck = false;
      extensions = (
        with vscode-extensions.vscode-marketplace;
        [
          esbenp.prettier-vscode
          github.vscode-github-actions
          github.vscode-pull-request-github
          golang.go
          hashicorp.hcl
          hashicorp.terraform
          jnoortheen.nix-ide
          mechatroner.rainbow-csv
          oderwat.indent-rainbow
          pkief.material-icon-theme
          ritwickdey.liveserver
          stylelint.vscode-stylelint
          yoavbls.pretty-ts-errors
        ]
        ++ (with pkgs.vscode-extensions; [
          jkillian.custom-local-formatters
        ])
      );

      userSettings = {
        "diffEditor.maxComputationTime" = 0;
        "editor.accessibilitySupport" = "off";
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[nix]" = {
          "editor.defaultFormatter" = "jkillian.custom-local-formatters";
        };
        "[terraform]" = {
          "editor.defaultFormatter" = "jkillian.custom-local-formatters";
          "prettier.enable" = false;
        };
        "[hcl]" = {
          "editor.defaultFormatter" = "jkillian.custom-local-formatters";
          "prettier.enable" = false;
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
            command = "nixfmt";
            languages = [ "nix" ];
          }
          {
            command = "terraform fmt -";
            languages = [
              "terraform"
              "hcl"
            ];
          }
        ];
        "files.associations" = {
          "*.tf" = "terraform";
          "*.tfvars" = "hcl";
          "*.tfvars.*" = "hcl";
          "*.hcl" = "hcl";
        };
        "files.insertFinalNewline" = true;
        "files.trimTrailingWhitespace" = true;
        "go.alternateTools" = {
          "go" = "${pkgs.go}/bin/go";
        };
        "[go]" = {
          "editor.defaultFormatter" = "golang.go";
        };
        "indentRainbow.indicatorStyle" = "light";
        "indentRainbow.lightIndicatorStyleLineWidth" = 4;
        "javascript.updateImportsOnFileMove.enabled" = "always";
        "javascript.validate.enable" = false;
        "liveServer.settings.donotShowInfoMsg" = true;
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
        "prettier.enable" = true;
        "prettier.singleQuote" = true;
        "security.workspace.trust.untrustedFiles" = "open";
        "search.exclude" = {
          "**/node_modules" = true;
          "**/dist" = true;
          "**/.direnv" = true;
          "**/*.tsbuildinfo" = true;
        };
        "window.openFoldersInNewWindow" = "off";
        "workbench.colorTheme" = "Default Dark+";
        "workbench.iconTheme" = "material-icon-theme";
        "workbench.panel.defaultLocation" = "right";
        "git.openRepositoryInParentFolders" = "never";
        "diffEditor.ignoreTrimWhitespace" = false;
        "stylelint.validate" = [ "scss" ];
        "typescript.updateImportsOnFileMove.enabled" = "always";
        "update.mode" = "none";
        "window.menuBarVisibility" = "toggle";
        "extensions.ignoreRecommendations" = true;
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
        {
          key = "ctrl+c";
          command = "workbench.action.terminal.copySelection";
          when = "terminalFocus && terminalTextSelected";
        }
        {
          key = "ctrl+v";
          command = "workbench.action.terminal.paste";
          when = "terminalFocus";
        }
        {
          key = "ctrl+i";
          command = "composerMode.agent";
        }
      ];
    };
  };
}
