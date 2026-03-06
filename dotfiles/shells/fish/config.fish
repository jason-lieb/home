# Disable greeting
set fish_greeting

# Environment variables
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx EDITOR "code"

fish_add_path $HOME/.local/bin
if test (uname) = "Darwin"
    fish_add_path --prepend $HOME/bin /opt/homebrew/bin /usr/local/bin
else
    set -gx SSH_ASKPASS /usr/bin/ksshaskpass
    set -gx SSH_ASKPASS_REQUIRE prefer
end

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
    if set -q AWS_PROFILE; and test -n "$AWS_PROFILE"
        set_color magenta
        echo -n " (aws:$AWS_PROFILE)"
    end
    set_color $fish_color_cwd
    if type -q docker; and docker ps -q 2>/dev/null | grep -q .
        echo -n " (docker)"
    end
    set_color normal
    echo -n "> "
end

# Aliases
source "$HOME/.config/posix/aliases.sh"
if test (uname) != "Darwin"
    alias arch-clean='sudo pacman -Rns (pacman -Qdtq); sudo pacman -Sc'
end

# Sources
if type -q zoxide
    zoxide init fish | source
end

if type -q direnv
    direnv hook fish | source
end

if type -q fnm
    fnm env --use-on-cd | source
end

set -gx PNPM_HOME "/Users/jason.lieb/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end

if test -f ~/.orbstack/shell/init2.fish
    source ~/.orbstack/shell/init2.fish
end
