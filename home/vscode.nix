{ pkgs, vscode-extensions, ... }:

{
  programs.vscode = {
    enable = true;
    extensions =
      (with vscode-extensions.vscode-marketplace; [
        # continue.dev
        esbenp.prettier-vscode
        haskell.haskell
        jkillian.custom-local-formatters
        jnoortheen.nix-ide
        justusadam.language-haskell
        mechatroner.rainbow-csv
        mhutchie.git-graph
        oderwat.indent-rainbow
        pkief.material-icon-theme
        stylelint.vscode-stylelint
        # supermaven.supermaven
        tomrijndorp.find-it-faster
        yoavbls.pretty-ts-errors
      ])
      ++ (with vscode-extensions.vscode-marketplace-release; [
        github.copilot
        github.copilot-chat
      ]);

    userSettings = {
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
      "haskell.checkProject" = false;
      "haskell.plugin.hlint.diagnosticsOn" = true;
      "haskell.trace.client" = "debug";
      "haskell.trace.server" = "messages";
      "haskell.manageHLS" = "PATH";
      "indentRainbow.indicatorStyle" = "light";
      "indentRainbow.lightIndicatorStyleLineWidth" = 4;
      "javascript.updateImportsOnFileMove.enabled" = "always";
      "javascript.validate.enable" = false;
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "${pkgs.nil}/bin/nil";
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
