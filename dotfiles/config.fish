# Load node / yarn
set -gx PATH ~/.nvm/versions/node/v16.20.0/bin $PATH

if not string match -q --regex "$PATH" "$HOME/.local/bin:$HOME/bin:"
    set -x PATH "$HOME/.local/bin" "$HOME/bin" $PATH
end

# Load zoxide
zoxide init fish | source

# set -gx PATH $PATH /nix/var/nix/profiles/default/bin
set -q GHCUP_INSTALL_BASE_PREFIX[1]; or set GHCUP_INSTALL_BASE_PREFIX $HOME ; set -gx PATH $HOME/.cabal/bin $PATH /home/jason/.ghcup/bin

###

# Aliases
alias b "bash"
alias c "clear"
alias cd "z"
alias g "git"
alias gac "git add -A; git commit -m"
alias la "ls -A"
alias ll "ls -l"
alias lr 'ls -R' # recursive ls
alias m "make"
alias mon-desk "~/home/utils/switch-to-desk-monitors.sh"
alias mon-tv "~/home/utils/switch-to-tv-monitor.sh"
alias main "git checkout main"
alias pull "git pull origin"
alias push "git push origin"
alias fpush "git push origin --force"
alias run-qa "git commit --allow-empty -m '[qa]'"
alias run-cy "git commit --allow-empty -m '[cy]'"
alias up "make update"
alias bran "git branch | tr '\\n' '\\n'"
alias dbran "git branch -D"
alias nbran "git checkout -b"
alias sbran "git checkout"
alias cd.. "cd .."
alias .. "cd .."
alias ... "cd ../.."
alias .... "cd ../../.."
alias ..... "cd ../../../.."
alias suod 'sudo'
alias enter-db 'docker exec -it freckle-megarepo-postgres bash -c "psql -U postgres -d classroom_dev"'
alias format-backend-whole 'stack exec -- fourmolu -i .'
alias format-backend 'git diff --name-only HEAD "*.hs" | xargs fourmolu -i'
alias rebase 'git fetch origin main && git rebase origin/main'
alias squash 'git rebase -i origin/main'
