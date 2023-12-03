# .bashrc

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

###

# Aliases
alias bran="git branch | tr '\n' '\n'"
alias c='clear'
alias dbran="git branch -D"
alias g='git'
alias gac='git add -A && git commit -m'
alias ll='ls -l'
alias la='ls -A'
alias main='git checkout main'
alias pull='git pull origin main'
alias push='git push origin'
alias run-qa="git commit --allow-empty -m '[qa]'"
