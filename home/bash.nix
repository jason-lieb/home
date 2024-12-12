{ ... }:

{
  programs.bash = {
    enable = true;
    bashrcExtra = ''
      eval "$(zoxide init bash)"

      # Custom prompt
      PS1_DIR='\[\033[1;34m\]'    # blue directory
      PS1_GIT='\[\033[0;36m\]'    # cyan git
      PS1_DOCKER='\[\033[0;32m\]' # green docker
      PS1_NIX='\[\033[0;33m\]'    # yellow nix
      PS1_RESET='\[\033[0m\]'     # reset color

      function git_branch {
        git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
      }

      function docker_status {
        if docker ps -q | grep -q .; then
          echo " (docker)"
        fi
      }

      function nix_shell_info {
        if [ -n "$IN_NIX_SHELL" ]; then
          if [ -z "$FLAKE_DIR" ]; then
            export FLAKE_DIR=$(basename $(pwd))
          fi
          echo " (nix: $FLAKE_DIR)"
        fi
      }

      PS1="\[$PS1_DIR\]\u@\h \w\[$PS1_GIT\]\$(git_branch)\[$PS1_DOCKER\]\$(docker_status)\[$PS1_NIX\]\$(nix_shell_info)\[$PS1_RESET\]> "

      # Custom functions
      grf() {
        if [ $# -eq 1 ]; then
          git branch -D $1
          git fetch origin $1
          git checkout $1
        else
          echo "Invalid number of arguments"
        fi
      }

      fr() {
        if [ "$(git rev-parse --abbrev-ref HEAD)" != "main" ]; then
          git checkout main
        fi
        git fetch origin main && git rebase origin/main
      }

      dev() {
        if [ "$(git rev-parse --abbrev-ref HEAD)" = "main" ]; then
          git stash
        else
          git stash && git checkout main
        fi
        nix develop -c fish
      }
    '';

    shellAliases = {
      # General
      c = "clear";
      la = "ls -A";
      ll = "ls -l";
      lr = "ls -R";

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
      gd = "git checkout -- .";
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
      b = "git branch";
      db = "git branch -D";
      nb = "git checkout -b";
      sb = "git checkout";
      fe = "git fetch origin main";
      re = "git rebase origin/main";
      rei = "git rebase -i origin/main";
      sq = "git rebase -i origin/main";

      # Github CLI
      pr = "gh pr create -t";
      prd = "gh pr create --draft -t";

      # Trigger Github Actions
      run-qa = "git commit --allow-empty -m '[qa]'";
      run-cy = "git commit --allow-empty -m '[cy]'";
      run-eph = "git commit --allow-empty -m '[ephemeral]'";
      run-dev = "git commit --allow-empty -m '[dev]'";

      # Misc
      ghce = "gh copilot explain";
      ghcs = "gh copilot suggest";
      ghcu = "gh extension install github/gh-copilot --force";
      enter-db = "docker exec -it freckle-megarepo-postgres bash -c \"psql -U postgres -d classroom_dev\"";
      docker-clean = "docker system prune -a";

      # Stack commands
      stb = "stack test --no-run-tests --fast --file-watch --watch-all";
      stbf = "stack test --no-run-tests --fast --file-watch --watch-all fancy-api";
      stt = "stack test --fast --file-watch --watch-all";
      sttf = "stack test --fast --file-watch --watch-all fancy-api";

      # Navigation and utilities
      home = "cd ~/home";
      mega = "code ~/megarepo";

      # Nix commands
      shell = "nix-shell -p";
      rs = "sudo nixos-rebuild switch --impure --flake /home/jason/home#${builtins.getEnv "HOSTNAME"}";
      rb = "sudo nixos-rebuild boot --impure --flake /home/jason/home#${builtins.getEnv "HOSTNAME"}";
      nix-update = "nix flake update";
      nix-clean = "sudo nix-collect-garbage --delete-older-than 3d && sudo /run/current-system/bin/switch-to-configuration boot";
    };
  };
}
