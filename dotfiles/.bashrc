# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# User specific aliases and functions -> sources additional config from ~/.bashrc.d/ directory
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# Load zoxide
eval "$(zoxide init bash)"

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Add nix to PATH
# export PATH=$PATH:/nix/var/nix/profiles/default/bin

###

# Aliases
alias f='fish'
alias c='clear'
alias cd="z"
alias g='git'
alias gac='git add -A && git commit -m'
alias la='ls -A'
alias ll='ls -l'
alias lr='ls -R' # recursive ls
alias m='make'
alias main='git checkout main'
alias mon-desk='~/home/utils/switch-to-desk-monitors.sh'
alias mon-tv='~/home/utils/switch-to-tv-monitor.sh'
alias pull='git pull origin main'
alias push='git push origin'
alias fpush="git push origin --force"
alias run-qa="git commit --allow-empty -m '[qa]'"
alias run-cy="git commit --allow-empty -m '[cy]'"
alias up="make update"
alias bran="git branch | tr '\n' '\n'"
alias dbran="git branch -D"
alias nbran="git checkout -b"
alias sbran='git checkout'
alias cd..="cd .."
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias suod='sudo'
alias enter-db='docker exec -it freckle-megarepo-postgres bash -c "psql -U postgres -d classroom_dev"'
alias format-backend-whole='stack exec -- fourmolu -i .'
alias format-backend='git diff --name-only HEAD "*.hs" | xargs fourmolu -i'
alias rebase='git fetch origin main && git rebase origin/main'
alias squash='git rebase -i origin/main'
