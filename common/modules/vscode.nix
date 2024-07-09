{ config, pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      #albert.TabOut
      #tom-rijndorp.finditfaster
      # yoavbls.pretty-ts-errors
      bbenoist.nix
      esbenp.prettier-vscode
      # github.vscode-github-actions
      github.copilot
      github.copilot-chat
      # gleam.gleam
      haskell.haskell
      jkillian.custom-local-formatters
      justusadam.language-haskell
      mechatroner.rainbow-csv
      mhutchie.git-graph
      # ms-python.python
      # ms-python.vscode-pylance
      oderwat.indent-rainbow
      pkief.material-icon-theme
    ];

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
          command = "fourmolu --stdin-input-file $file";
          languages = [ "haskell" ];
        }
        {
          command = "nixfmt $file";
          languages = [ "nix" ];
        }
      ];
      "files.insertFinalNewline" = true;
      "files.trimTrailingWhitespace" = true;
      "haskell.checkProject" = false;
      "haskell.formattingProvider" = "fourmolu";
      "haskell.manageHLS" = "GHCup";
      "haskell.plugin.hlint.diagnosticsOn" = true;
      "haskell.trace.client" = "debug";
      "haskell.trace.server" = "messages";
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
      "git.openRepositoryInParentFolders" = "never";
      "diffEditor.ignoreTrimWhitespace" = false;
      "typescript.updateImportsOnFileMove.enabled" = "always";
      "update.showNotifications" = false;
      "update.mode" = "none";
      "eslint.workingDirectories" = [
        "~/megarepo/frontend/educator"
        "~/megarepo/frontend/educator/classroom"
        "~/megarepo/frontend/educator/school"
        "~/megarepo/frontend/educator/entities"
        "~/megarepo/frontend/educator/materials"
      ];
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
