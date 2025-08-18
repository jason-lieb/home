{ ... }:

let
  shellAliases = {
    # General
    c = "clear";
    la = "ls -A";
    ll = "ls -l";
    lr = "ls -R"; # recursive ls
    cat = "bat";

    # Navigation
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    "....." = "cd ../../../..";
    "......" = "cd ../../../../..";

    # Shells
    f = "fish";

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
    pull = "git pull --rebase origin";
    push = "git push origin";
    fpush = "git push origin --force-with-lease";

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

    # Github Cli
    pr = "gh pr create -t";
    prd = "gh pr create --draft -t";

    # Trigger Github Actions
    run-qa = "git commit --allow-empty -m '[qa]'";
    run-cy = "git commit --allow-empty -m '[cy]'";
    run-eph = "git commit --allow-empty -m '[ephemeral]'";
    run-dev = "git commit --allow-empty -m '[dev]'";

    # Misc
    code = "cursor";
    enter-db = ''docker exec -it freckle-megarepo-postgres bash -c "psql -U postgres -d classroom_dev"'';
    docker-clean = "docker system prune -a";
    stb = "stack test --no-run-tests --fast --file-watch --watch-all";
    stbf = "stack test --no-run-tests --fast --file-watch --watch-all fancy-api";
    stbj = "stack test --no-run-tests --fast --file-watch --watch-all jobs";
    stbfj = "stack test --no-run-tests --fast --file-watch --watch-all fancy-api jobs";
    stbjf = "stack test --no-run-tests --fast --file-watch --watch-all fancy-api jobs";
    stt = "stack test --fast --file-watch --watch-all";
    sttf = "stack test --fast --file-watch --watch-all fancy-api";
    sttj = "stack test --fast --file-watch --watch-all jobs";
    sttfj = "stack test --fast --file-watch --watch-all fancy-api jobs";
    sttjf = "stack test --fast --file-watch --watch-all fancy-api jobs";
    stack-clean = "find ~/.stack -mindepth 1 -not -name 'config.yaml' -exec rm -rf {} + 2>/dev/null";
    kill-backend = "sudo pkill -x fancy-api; sudo pkill -x jobs";
    up = "make services.restart";
    upd = "make update";
    w = "yarn watch";
    down = "pushd ~/megarepo/backend; make services.stop; popd";
    msr = "make services.restart";
    ze = "zellij";
    p = "pnpm";
    y = "yarn";
    home = "cd ~/home";
    mega = "code ~/megarepo";
    format-backend = "stack exec -- fourmolu -i ."; # Format entire backend

    # Nix
    shell = "nix-shell -p";
    dev = "nix develop -c fish";
    rs = "sudo nixos-rebuild switch --impure --flake /home/jason/home#${builtins.getEnv "HOSTNAME"}";
    rsp = "sudo nixos-rebuild switch --impure --flake /home/jason/home#${builtins.getEnv "HOSTNAME"} --profile-name";
    rb = "sudo nixos-rebuild boot --impure --flake /home/jason/home#${builtins.getEnv "HOSTNAME"}";
    rbp = "sudo nixos-rebuild boot --impure --flake /home/jason/home#${builtins.getEnv "HOSTNAME"} --profile-name";
    nix-clean = "sudo nix-collect-garbage --delete-older-than 7d && sudo /run/current-system/bin/switch-to-configuration boot";
  };

  fishPrompt = ''
    set fish_greeting
    source (zoxide init fish | psub)

    function fish_prompt
      # jason
      set_color $fish_color_cwd
      echo -n (whoami)

      # @hostname
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

      # (docker)
      set_color $fish_color_cwd
      if docker ps -q | grep -q .
        echo -n " (docker)"
      end

      # (nix: flake-name)
      if test -n "$IN_NIX_SHELL"
        if test -n "$DIRENV_DIR"
          set -gx FLAKE_DIR (basename (string sub -s 2 -- "$DIRENV_DIR"))
        else if not set -q FLAKE_DIR
          set -gx FLAKE_DIR (basename (pwd))
        end
        echo -n " (nix: $FLAKE_DIR)"
      end

      set_color normal
      echo -n "> "
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

    function fr
      if test (git rev-parse --abbrev-ref HEAD) != "main"
        git checkout main
      end

      git fetch origin main && git rebase origin/main
    end
  '';

  bashPrompt = ''
    eval "$(zoxide init bash)"

    shopt -s checkwinsize   # Update LINES and COLUMNS after each command
    bind "set enable-bracketed-paste on"  # Better paste handling
    bind "set horizontal-scroll-mode off" # Wrap lines instead of scrolling
    bind "set show-all-if-ambiguous on"  # Better completion

    PS1_DIR='\[\033[1;34m\]'    # blue directory
    PS1_GIT='\[\033[0;36m\]'    # cyan git
    PS1_DOCKER='\[\033[0;32m\]' # green docker
    PS1_NIX='\[\033[0;33m\]'    # yellow nix
    PS1_RESET='\[\033[0m\]'     # reset color

    git_branch() {
      git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
    }

    docker_status() {
      if docker ps -q | grep -q .; then
        echo " (docker)"
      fi
    }

    nix_shell_info() {
      if [ -n "$IN_NIX_SHELL" ]; then
        if [ -z "$FLAKE_DIR" ]; then
          export FLAKE_DIR=$(basename $(pwd))
        fi
        echo " (nix: $FLAKE_DIR)"
      fi
    }

    PS1="\[$PS1_DIR\]\u@\h \w\[$PS1_GIT\]\$(git_branch)\[$PS1_DOCKER\]\$(docker_status)\[$PS1_NIX\]\$(nix_shell_info)\[$PS1_RESET\]> "

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
  '';
in
{
  programs.fish = {
    enable = true;
    interactiveShellInit = fishPrompt;
    shellInit = ''
      set fish_user_paths /home/jason/bin /home/jason/.local/bin /home/jason/.nix-profile/bin /nix/var/nix/profiles/default/bin
    '';
    inherit shellAliases;
  };

  programs.bash = {
    enable = true;
    bashrcExtra = bashPrompt;
    inherit shellAliases;
  };

}
