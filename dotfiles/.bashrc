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

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Add nix to PATH
# export PATH=$PATH:/nix/var/nix/profiles/default/bin

###

# Aliases
alias bran="git branch | tr '\n' '\n'"
alias c='clear'
alias dbran="git branch -D"
alias g='git'
alias gac='git add -A && git commit -m'
alias ll='ls -l'
alias la='ls -A'
alias m='make'
alias main='git checkout main'
alias mon-desk='~/home/utils/switch-to-desk-monitors.sh'
alias mon-tv='~/home/utils/switch-to-tv-monitor.sh'
alias pull='git pull origin main'
alias push='git push origin'
alias run-qa="git commit --allow-empty -m '[qa]'"
alias run-cy="git commit --allow-empty -m '[cy]'"
alias update="make update"
