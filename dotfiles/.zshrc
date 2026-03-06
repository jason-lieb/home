# Enable prompt substitution
setopt PROMPT_SUBST

# Environment variables
export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR="code"
export PATH="$HOME/.local/bin:$PATH"
if [[ "$(uname)" == "Darwin" ]]; then
    export PATH="$HOME/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
else
    export SSH_ASKPASS=/usr/bin/ksshaskpass
    export SSH_ASKPASS_REQUIRE=prefer
fi

# Prompt
PS1='%F{blue}%n@%m %~%f%F{cyan}$(git_branch)%f%F{magenta}$(aws_profile)%f%F{green}$(docker_status)%f> '

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
    eval "$(zoxide init zsh)"
fi

if command -v direnv &>/dev/null; then
    eval "$(direnv hook zsh)"
fi

if command -v fnm &>/dev/null; then
    eval "$(fnm env --use-on-cd)"
fi

export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
esac

if [[ -f ~/.orbstack/shell/init.zsh ]]; then
    source ~/.orbstack/shell/init.zsh
fi
