# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Check window size after each command
shopt -s checkwinsize

# Enable bracketed paste and other readline settings
if [[ $- == *i* ]]; then
    bind "set enable-bracketed-paste on"
    bind "set horizontal-scroll-mode off"
    bind "set show-all-if-ambiguous on"
fi

# Environment variables
source "$HOME/.config/posix/env.sh"

# Prompt
PS1_DIR='\[\033[1;34m\]'
PS1_GIT='\[\033[0;36m\]'
PS1_AWS='\[\033[0;35m\]'
PS1_DOCKER='\[\033[0;32m\]'
PS1_RESET='\[\033[0m\]'

PS1="$PS1_DIR\u@\h \w$PS1_GIT\$(git_branch)$PS1_AWS\$(aws_profile)$PS1_DOCKER\$(docker_status)$PS1_RESET> "

# Functions
source "$HOME/.config/posix/functions.sh"

# Aliases
source "$HOME/.config/posix/aliases.sh"
alias awsp='source "$(brew --prefix awsp)/_source-awsp.sh"'
if [[ "$(uname)" != "Darwin" ]]; then
    alias arch-clean='sudo pacman -Rns $(pacman -Qdtq); sudo pacman -Sc'
fi

# Sources
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi

if command -v direnv &>/dev/null; then
    eval "$(direnv hook bash)"
fi

if command -v fnm &>/dev/null; then
    eval "$(fnm env --use-on-cd)"
fi

if [[ -f ~/.orbstack/shell/init.bash ]]; then
    source ~/.orbstack/shell/init.bash
fi
