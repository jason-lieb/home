{ ... }:

{
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set fish_greeting
      source (zoxide init fish | psub)

      function fish_prompt
        # jason
        set_color $fish_color_cwd
        echo -n (whoami)

        # @debian
        set_color normal
        echo -n "@"(hostname)" "

        # ~/home
        set_color $fish_color_cwd
        echo -n (prompt_pwd)

        # (main)
        set_color normal
        if type -q __fish_git_prompt
          __fish_git_prompt
        end

        # (nix: educator)
        set_color $fish_color_cwd
        if test -n "$IN_NIX_SHELL"
          if not set -q FLAKE_DIR
            set -gx FLAKE_DIR (basename (pwd))
          end
          echo -n " (nix: $FLAKE_DIR)"
        end

        set_color normal
        echo -n "> "
      end

      function st
        switch (count $argv)
          case 0
            stack test --fast --file-watch --watch-all fancy-api jobs
          case 1
            stack test --fast --file-watch --watch-all --ta '-m "'$argv[1]'"' fancy-api jobs
          case '*'
            echo "Too many arguments"
        end
      end

      function grf
        if test (count $argv) -eq 1
          git branch -D $argv
          git fetch origin $argv
          git checkout $argv
        else
          echo "Invalid number of arguments"
        end
      end
    '';

    shellInit = ''
      set fish_user_paths /home/jason/bin /home/jason/.local/bin /home/jason/.nix-profile/bin /nix/var/nix/profiles/default/bin
    '';

    shellAliases = {
      # General
      c = "clear";
      la = "ls -A";
      ll = "ls -l";
      lr = "ls -R"; # recursive ls
      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      "......" = "cd ../../../../..";
      # Git Basics
      g = "git";
      ga = "git add";
      gaa = "git add -A";
      gap = "git add -p";
      gf = "git commit --fixup";
      gaf = "git add -A; git commit --fixup";
      gfh = "git commit --fixup HEAD";
      gafh = "git add -A; git commit --fixup HEAD";
      gc = "git commit -m";
      gac = "git add -A; git commit -m";
      gd = "git checkout -- ."; # Drops current uncommitted changes
      gdiff = "git diff";
      gdiffs = "git diff --staged";
      gr = "git reset HEAD^";
      gl = "git log --oneline --ancestry-path origin/main^..HEAD";
      gcp = "git cherry-pick";
      main = "git checkout main";
      pull = "git pull origin";
      push = "git push origin";
      fpush = "git push origin --force";
      # Git Stash
      gs = "git stash push";
      gsm = "git stash push -m";
      gsd = "git stash drop";
      gsl = "git stash list";
      gsp = "git stash pop";
      # Git Branch
      b = "git branch | tr '\\n' '\\n'";
      db = "git branch -D";
      nb = "git checkout -b";
      sb = "git checkout";
      fe = "git fetch origin main";
      re = "git rebase origin/main";
      fr = "git fetch origin main && git rebase origin/main";
      rei = "git rebase -i origin/main";
      sq = "git rebase -i origin/main";
      # Github Cli
      pr = "gh pr create -t";
      prd = "gh pr create --draft -t";
      # Trigger Github Actions
      run-qa = "git commit --allow-empty -m '[qa]'";
      run-cy = "git commit --allow-empty -m '[cy]'";
      run-eph = "git commit --allow-empty -m '[ephemeral]'";
      run-dev = "git commit --allow-empty -m '[dev]'";
      # Gnome
      fix-gnome-settings = ''
        gsettings set org.gnome.shell enabled-extensions "['display-brightness-ddcutil@themightydeity.github.com', 'launch-new-instance@gnome-shell-extensions.gcampax.github.com', 'caffeine@patapon.info']"
        gsettings set org.gnome.desktop.wm.preferences num-workspaces 4
      '';
      # Misc
      ghce = "gh copilot explain";
      ghcs = "gh copilot suggest";
      ghcu = "gh extension install github/gh-copilot --force";
      mon-desk = "~/home/utils/switch-to-desk-monitors.sh";
      mon-tv = "~/home/utils/switch-to-tv-monitor.sh";
      enter-db = ''docker exec -it freckle-megarepo-postgres bash -c "psql -U postgres -d classroom_dev"'';
      docker-clean = "docker system prune -a";
      mw = "stack test --no-run-tests --fast --file-watch --watch-all fancy-api";
      stf = "stack test --fast --file-watch --watch-all fancy-api";
      stj = "stack test --fast --file-watch --watch-all jobs";
      up = "make update";
      msr = "make services.restart";
      down = "pushd ~/megarepo/backend; and make services.stop; and popd";
      ze = "zellij";
      mega = "code ~/megarepo";
      format-backend = "stack exec -- fourmolu -i ."; # Format entire backend
      # Nix
      hs = "home-manager -b bak switch --impure --flake /home/jason/home#jason@debian";
      rd = "darwin-rebuild switch --impure --flake /Users/jason.lieb/home#macbook";
      rs = "sudo nixos-rebuild switch --impure --flake /home/jason/home#${builtins.getEnv "HOSTNAME"}";
      rb = "sudo nixos-rebuild boot --impure --flake /home/jason/home#${builtins.getEnv "HOSTNAME"}";
      install-darwin = "nix run nix-darwin -- switch --flake /Users/jason.lieb/home#macbook";
      nix-update = "nix flake update";
      nix-clean = "sudo nix-collect-garbage --delete-older-than 3d && sudo /run/current-system/bin/switch-to-configuration boot";
      dev = "nix develop -c fish";
      # dev = "git stash; and git checkout main; and nix develop -c fish; and git checkout -; and git stash pop";
      # dev = "set stashed 0; git stash | grep -q 'No local changes to save' || set stashed 1; and git checkout main; and nix develop -c fish; and git checkout -; and test $stashed -eq 1; and git stash pop";
    };
    # Not Currently Needed
    # format-backend =
    #   ''git diff --name-only HEAD "*.hs" | xargs fourmolu -i'';
  };
}
