{ config, pkgs, ... }:

{
  programs.zoxide.enable = true;

  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set fish_greeting
      source (zoxide init fish | psub)
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
    '';

    shellInit = ''
      set fish_user_paths /home/jason/bin /home/jason/.local/bin /home/jason/.nix-profile/bin
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
      gap = "git add -p";
      gc = "git commit -m";
      gcs = "git commit --squash=HEAD -m 'squash'";
      gac = "git add -A; git commit -m";
      gacs = "git add -A; git commit --squash=HEAD -m 'squash'";
      # Look into using git commit --fixup
      gcp = "git cherry-pick";
      main = "git checkout main";
      pull = "git pull origin";
      push = "git push origin";
      fpush = "git push origin --force";
      # Git Stash
      gs = "git stash push";
      gsd = "git stash drop";
      gsl = "git stash list";
      gsp = "git stash pop";
      # Git Branch
      b = "git branch | tr '\\n' '\\n'";
      db = "git branch -D";
      nb = "git checkout -b";
      sb = "git checkout";
      re = "git fetch origin main && git rebase origin/main";
      sq = "git rebase -i origin/main";
      # Github Cli
      pr = "gh pr create";
      prd = "gh pr create --draft";
      # Trigger Github Actions
      run-qa = "git commit --allow-empty -m '[qa]'";
      run-cy = "git commit --allow-empty -m '[cy]'";
      run-eph = "git commit --allow-empty -m '[ephemeral]'";
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
      clear-docker-cache = "docker system prune -a";
      mw = "stack test --no-run-tests --fast --file-watch --watch-all fancy-api";
      stf = "stack test --fast --file-watch --watch-all fancy-api";
      stj = "stack test --fast --file-watch --watch-all jobs";
      up = "make update";
      down = "pushd ~/megarepo/backend; and make services.stop; and popd";
      # Nix
      rs = "sudo nixos-rebuild switch --impure --flake /home/jason/home-nix#${builtins.getEnv "HOSTNAME"}";
      rb = "sudo nixos-rebuild boot --impure --flake /home/jason/home-nix#${builtins.getEnv "HOSTNAME"}";
      nix-update = "nix flake update";
      nix-clean = "sudo nix-collect-garbage --delete-older-than 3d && sudo /run/current-system/bin/switch-to-configuration boot";
    };
    # Not Currently Needed
    # format-backend-whole = "stack exec -- fourmolu -i .";
    # format-backend =
    #   ''git diff --name-only HEAD "*.hs" | xargs fourmolu -i'';
  };
}
