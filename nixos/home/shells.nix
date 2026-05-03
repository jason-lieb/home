{
  config,
  hostname,
  ...
}:
let
  homeDir = config.home.homeDirectory;

  shellAbbrs = {
    eit = "exit";
    c = "clear";
    la = "ls -A";
    ll = "ls -l";
    lr = "ls -R";
    cat = "bat";
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    "....." = "cd ../../../..";
    "......" = "cd ../../../../..";
    f = "fish";
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
    pull = "git pull --rebase origin";
    push = "git push origin";
    fpush = "git push origin --force-with-lease";
    fetch = "git fetch origin";
    gs = "git stash push -u";
    gsm = "git stash push -u -m";
    gsd = "git stash drop";
    gsl = "git stash list";
    gsp = "git stash pop";
    b = "git branch";
    db = "git branch -D";
    nb = "git checkout -b";
    sb = "git checkout";
    fe = "git fetch origin main";
    re = "git rebase main";
    rei = "git rebase -i main";
    sq = "GIT_SEQUENCE_EDITOR=true git rebase -i main";
    abort = "git rebase --abort";
    pr = "gh pr create -t";
    prd = "gh pr create --draft -t";
    docker-clean = "docker system prune -a";
    p = "pnpm";
    oc = "opencode";
    home = "cd ~/home";
    shell = "nix-shell -p";
    dev = "nix develop -c fish";
    rs = "sudo nixos-rebuild switch --impure --flake ${homeDir}/home#${hostname}";
    rsp = "sudo nixos-rebuild switch --impure --flake ${homeDir}/home#${hostname} --profile-name";
    rb = "sudo nixos-rebuild boot --impure --flake ${homeDir}/home#${hostname}";
    rbp = "sudo nixos-rebuild boot --impure --flake ${homeDir}/home#${hostname} --profile-name";
    nix-clean = "sudo nix-collect-garbage --delete-older-than 7d && sudo /run/current-system/bin/switch-to-configuration boot";
    bluetooth = "bluetoothctl power on";
  };

  fishPrompt = ''
    set fish_greeting
    source (zoxide init fish | psub)

    function fish_prompt
      set_color $fish_color_cwd
      echo -n (whoami)
      set_color normal
      echo -n "@"(hostname)" "
      set_color $fish_color_cwd
      echo -n (prompt_pwd)
      set_color normal
      if type -q __fish_git_prompt
        __fish_git_prompt
      end
      set_color $fish_color_cwd
      if type -q docker; and docker ps -q 2>/dev/null | grep -q .
        echo -n " (docker)"
      end
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
        git branch -D "$argv"
        git fetch origin "$argv"
        git checkout "$argv"
      else
        echo "Invalid number of arguments"
      end
    end

    function main
      set main_worktree (git worktree list --porcelain 2>/dev/null | grep "^worktree " | head -1 | awk '{print $2}')
      if test -z "$main_worktree"
        echo "Not in a git repository"
        return 1
      end
      set current_toplevel (git rev-parse --show-toplevel 2>/dev/null)
      if test "$current_toplevel" = "$main_worktree"
        git checkout main
      else if test "$PWD" != "$main_worktree"
        cd $main_worktree
      else
        git checkout main
      end
    end

    function nw
      if test (count $argv) -ne 1
        echo "Usage: nw <branch-name>"
        return 1
      end
      set full_branch $argv[1]
      set dir (string replace --regex '^jl/' "" $full_branch)
      set root (git worktree list --porcelain | head -1 | string replace --regex '^worktree ' "")
      if git show-ref --verify --quiet "refs/heads/$full_branch"
        git worktree add "$root/.worktrees/$dir" "$full_branch"
      else
        git worktree add "$root/.worktrees/$dir" -b "$full_branch" main
      end
    end

    function nwe
      if test (count $argv) -ne 1
        echo "Usage: nwe <branch-name>"
        return 1
      end
      set full_branch $argv[1]
      set dir (string replace --regex '^jl/' "" $full_branch)
      set root (git worktree list --porcelain | head -1 | string replace --regex '^worktree ' "")
      if git show-ref --verify --quiet "refs/heads/$full_branch"
        git worktree add "$root/.worktrees/$dir" "$full_branch"
      else
        git worktree add "$root/.worktrees/$dir" -b "$full_branch" main
      end
      and cd "$root/.worktrees/$dir"
    end

    function sw
      if test (count $argv) -ne 1
        echo "Usage: sw <branch-name>"
        return 1
      end
      set dir (string replace --regex '^jl/' "" $argv[1])
      set root (git worktree list --porcelain 2>/dev/null | head -1 | string replace --regex '^worktree ' "")
      if test $status -ne 0
        echo "Not in a git repository"
        return 1
      end
      set worktree "$root/.worktrees/$dir"
      if not test -d $worktree
        echo "No worktree found for '$dir'"
        return 1
      end
      cd $worktree
    end

    function dw
      if test (count $argv) -ne 1
        echo "Usage: dw <branch-name>"
        return 1
      end
      set dir (string replace --regex '^jl/' "" $argv[1])
      set root (git worktree list --porcelain 2>/dev/null | head -1 | string replace --regex '^worktree ' "")
      if test $status -ne 0
        echo "Not in a git repository"
        return 1
      end
      set worktree "$root/.worktrees/$dir"
      if not test -d $worktree
        echo "No worktree found for '$dir'"
        return 1
      end
      git worktree remove $worktree
    end

    function fr
      set main_repo (git worktree list --porcelain | grep '^worktree ' | head -1 | string replace 'worktree ' "")
      set current_branch (git -C $main_repo rev-parse --abbrev-ref HEAD)

      if test $current_branch = "main"
        git -C $main_repo fetch origin && git -C $main_repo rebase origin/main && git -C $main_repo remote prune origin
      else
        git -C $main_repo fetch origin main:main && git -C $main_repo remote prune origin
      end
      or return 1
    end
  '';

  bashPrompt = ''
    eval "$(zoxide init bash)"
    shopt -s checkwinsize

    if [[ $- == *i* ]]; then
      bind "set enable-bracketed-paste on"
      bind "set horizontal-scroll-mode off"
      bind "set show-all-if-ambiguous on"
    fi

    PS1_DIR='\[\033[1;34m\]'
    PS1_GIT='\[\033[0;36m\]'
    PS1_DOCKER='\[\033[0;32m\]'
    PS1_NIX='\[\033[0;33m\]'
    PS1_RESET='\[\033[0m\]'

    git_branch() {
      git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
    }

    docker_status() {
      if command -v docker &>/dev/null && docker ps -q 2>/dev/null | grep -q .; then
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
        git branch -D "$1"
        git fetch origin "$1"
        git checkout "$1"
      else
        echo "Invalid number of arguments"
      fi
    }

    main() {
      local main_worktree
      main_worktree=$(git worktree list --porcelain 2>/dev/null | grep "^worktree " | head -1 | awk '{print $2}')
      if [ -z "$main_worktree" ]; then
        echo "Not in a git repository"
        return 1
      fi
      local current_toplevel
      current_toplevel=$(git rev-parse --show-toplevel 2>/dev/null)
      if [ "$current_toplevel" = "$main_worktree" ]; then
        git checkout main
      elif [ "$PWD" != "$main_worktree" ]; then
        cd "$main_worktree"
      else
        git checkout main
      fi
    }

    nw() {
      if [ $# -ne 1 ]; then
        echo "Usage: nw <branch-name>"
        return 1
      fi
      local full_branch="$1"
      local dir="''${full_branch#jl/}"
      local root
      root=$(git worktree list --porcelain | head -1 | sed 's/^worktree //')
      if git show-ref --verify --quiet "refs/heads/$full_branch"; then
        git worktree add "$root/.worktrees/$dir" "$full_branch"
      else
        git worktree add "$root/.worktrees/$dir" -b "$full_branch" main
      fi
    }

    nwe() {
      if [ $# -ne 1 ]; then
        echo "Usage: nwe <branch-name>"
        return 1
      fi
      local full_branch="$1"
      local dir="''${full_branch#jl/}"
      local root
      root=$(git worktree list --porcelain | head -1 | sed 's/^worktree //')
      if git show-ref --verify --quiet "refs/heads/$full_branch"; then
        git worktree add "$root/.worktrees/$dir" "$full_branch"
      else
        git worktree add "$root/.worktrees/$dir" -b "$full_branch" main
      fi && cd "$root/.worktrees/$dir"
    }

    sw() {
      if [ $# -ne 1 ]; then
        echo "Usage: sw <branch-name>"
        return 1
      fi
      local dir="''${1#jl/}"
      local root
      root=$(git worktree list --porcelain 2>/dev/null | head -1 | sed 's/^worktree //') || { echo "Not in a git repository"; return 1; }
      local worktree="$root/.worktrees/$dir"
      if [ ! -d "$worktree" ]; then
        echo "No worktree found for '$dir'"
        return 1
      fi
      cd "$worktree"
    }

    dw() {
      if [ $# -ne 1 ]; then
        echo "Usage: dw <branch-name>"
        return 1
      fi
      local dir="''${1#jl/}"
      local root
      root=$(git worktree list --porcelain 2>/dev/null | head -1 | sed 's/^worktree //') || { echo "Not in a git repository"; return 1; }
      local worktree="$root/.worktrees/$dir"
      if [ ! -d "$worktree" ]; then
        echo "No worktree found for '$dir'"
        return 1
      fi
      git worktree remove "$worktree"
    }

    fr() {
      local main_repo current_branch
      main_repo=$(git worktree list --porcelain | grep '^worktree ' | head -1 | sed 's/^worktree //')
      current_branch=$(git -C "$main_repo" rev-parse --abbrev-ref HEAD)

      if [ "$current_branch" = "main" ]; then
        git -C "$main_repo" fetch origin && git -C "$main_repo" rebase origin/main && git -C "$main_repo" remote prune origin
      else
        git -C "$main_repo" fetch origin main:main && git -C "$main_repo" remote prune origin
      fi || return 1
    }
  '';

in
{
  programs.fish = {
    enable = true;
    interactiveShellInit = fishPrompt;
    shellInit = ''
      set fish_user_paths ${homeDir}/bin ${homeDir}/.local/bin ${homeDir}/.nix-profile/bin /nix/var/nix/profiles/default/bin
    '';
    inherit shellAbbrs;
  };

  programs.bash = {
    enable = true;
    bashrcExtra = bashPrompt;
    shellAliases = shellAbbrs;
  };

}
