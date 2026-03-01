# Bash configuration

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Initialize zoxide
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi

# Check window size after each command
shopt -s checkwinsize

# Enable bracketed paste and other readline settings
if [[ $- == *i* ]]; then
    bind "set enable-bracketed-paste on"
    bind "set horizontal-scroll-mode off"
    bind "set show-all-if-ambiguous on"
fi

# Environment variables
export EDITOR="code"
if [[ "$(uname)" == "Darwin" ]]; then
    export PATH="$HOME/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
else
    export SSH_ASKPASS=/usr/bin/ksshaskpass
    export SSH_ASKPASS_REQUIRE=prefer
    export PATH="$HOME/.local/bin:$PATH"
fi

# Prompt
PS1_DIR='\[\033[1;34m\]'
PS1_GIT='\[\033[0;36m\]'
PS1_DOCKER='\[\033[0;32m\]'
PS1_RESET='\[\033[0m\]'

git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

docker_status() {
    if command -v docker &>/dev/null && docker ps -q 2>/dev/null | grep -q .; then
        echo " (docker)"
    fi
}

PS1="$PS1_DIR\u@\h \w$PS1_GIT\$(git_branch)$PS1_DOCKER\$(docker_status)$PS1_RESET> "

# Functions
grf() {
    if [ $# -eq 1 ]; then
        git branch -D "$1"
        git fetch origin "$1"
        git checkout "$1"
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

# Navigation
alias c="clear"
alias la="ls -A"
alias ll="ls -l"
alias lr="ls -R"
alias cat="bat"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."
alias f="fish"
alias home="cd ~/home"

# Git aliases
alias g="git"
alias ga="git add"
alias gaa="git add -A"
alias gap="git add -p"
alias gf="git commit --fixup"
alias gaf="git add -A; git commit --fixup"
alias gfh="git commit --fixup HEAD"
alias gafh="git add -A; git commit --fixup HEAD"
alias gc="git commit -m"
alias gac="git add -A; git commit -m"
alias gd="git checkout -- ."
alias gdiff="git diff"
alias gdiffs="git diff --staged"
alias gr="git reset HEAD^"
alias gl="git log --oneline --ancestry-path origin/main^..HEAD"
alias gcp="git cherry-pick"
alias main="git checkout main"
alias pull="git pull --rebase origin"
alias push="git push origin"
alias fpush="git push origin --force-with-lease"
alias fetch="git fetch origin"
alias gs="git stash push -u"
alias gsm="git stash push -u -m"
alias gsd="git stash drop"
alias gsl="git stash list"
alias gsp="git stash pop"
alias b="git branch"
alias db="git branch -D"
alias nb="git checkout -b"
alias sb="git checkout"
alias fe="git fetch origin main"
alias re="git rebase origin/main"
alias rei="git rebase -i origin/main"
alias pr="gh pr create -t"
alias prd="gh pr create --draft -t"

# Development
alias p="pnpm"
alias docker-clean="docker system prune -a"

# Platform-specific
if [[ "$(uname)" != "Darwin" ]]; then
    alias arch-clean='sudo pacman -Rns $(pacman -Qdtq); sudo pacman -Sc'
fi

# Initialize direnv
if command -v direnv &>/dev/null; then
    eval "$(direnv hook bash)"
fi
