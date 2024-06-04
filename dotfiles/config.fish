# Adds bin to Path
if not string match -q --regex "$PATH" "$HOME/.local/bin:$HOME/bin:"
    set -x PATH "$HOME/.local/bin" "$HOME/bin" $PATH
end

# Clear fish greeting
set fish_greeting

# Load node / yarn
set -gx PATH ~/.nvm/versions/node/v18.19.1/bin $PATH

# Load zoxide
zoxide init fish | source

# Add Nix to Path
# set -gx PATH $PATH /nix/var/nix/profiles/default/bin

# Add GHCUP to Path
set -q GHCUP_INSTALL_BASE_PREFIX[1]; or set GHCUP_INSTALL_BASE_PREFIX $HOME ; set -gx PATH $HOME/.cabal/bin $PATH /home/jason/.ghcup/bin

# Aliases
## General
alias c "clear"
alias la "ls -A"
alias ll "ls -l"
alias lr 'ls -R'
alias up "make update"
## Navigation
alias cd "z"
alias .. "cd .."
alias ... "cd ../.."
alias .... "cd ../../.."
alias ..... "cd ../../../.."
alias ...... "cd ../../../../.."
## Git
### Git Basics
alias g "git"
alias ga "git add"
alias gap "git add -p"
alias gc "git commit -m"
alias gcs "git commit --squash=HEAD -m 'squash'"
alias gac "git add -A; git commit -m"
alias gacs "git add -A; git commit --squash=HEAD -m 'squash'"
# Look into using git commit --fixup
alias gcp 'git cherry-pick'
alias main "git checkout main"
alias pull "git pull origin"
alias push "git push origin"
alias fpush "git push origin --force"
### Git Stash
alias gs "git stash"
alias gsd "git stash drop"
alias gsl "git stash list"
alias gsp "git stash pop"
### Git Branch
alias b "git branch | tr '\\n' '\\n'"
alias db "git branch -D"
alias nb "git checkout -b"
alias sb "git checkout"
alias re 'git fetch origin main && git rebase origin/main'
alias sq 'git rebase -i origin/main'
## Trigger Github Actions
alias run-qa "git commit --allow-empty -m '[qa]'"
alias run-cy "git commit --allow-empty -m '[cy]'"
alias run-eph "git commit --allow-empty -m '[ephemeral]'"
## Misc
alias ghce "gh copilot explain"
alias ghcs "gh copilot suggest"
alias ghcu "gh extension install github/gh-copilot --force"
alias mon-desk "~/home/utils/switch-to-desk-monitors.sh"
alias mon-tv "~/home/utils/switch-to-tv-monitor.sh"
alias enter-db 'docker exec -it freckle-megarepo-postgres bash -c "psql -U postgres -d classroom_dev"'
alias clear-docker-cache 'docker system prune -a'
alias mw "stack build --no-run-tests --fast --file-watch --watch-all fancy-api"
alias stf "stack test --fast --file-watch --watch-all fancy-api"
alias stj "stack test --fast --file-watch --watch-all jobs"
## Functions
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
## Reference
# alias format-backend-whole 'stack exec -- fourmolu -i .'
# alias format-backend 'git diff --name-only HEAD "*.hs" | xargs fourmolu -i'
