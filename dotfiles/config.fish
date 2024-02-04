if status is-interactive
    # Commands to run in interactive sessions can go here
end

if not string match -q --regex "$PATH" "$HOME/.local/bin:$HOME/bin:"
    set -x PATH "$HOME/.local/bin" "$HOME/bin" $PATH
end

# Add nix to PATH
set -gx PATH $PATH /nix/var/nix/profiles/default/bin

###

# Aliases
alias bran "git branch | tr '\\n' '\\n'"
alias c "clear"
alias dbran "git branch -D"
alias g "git"
alias gac "git add -A; git commit -m"
alias ll "ls -l"
alias la "ls -A"
alias m "make"
alias mon-desk "~/home/utils/switch-to-desk-monitors.sh"
alias mon-tv "~/home/utils/switch-to-tv-monitor.sh"
alias main "git checkout main"
alias pull "git pull origin main"
alias push "git push origin"
alias run-qa "git commit --allow-empty -m '[qa]'"
alias update "make update"

# Don't know if I need
set -q GHCUP_INSTALL_BASE_PREFIX[1]; or set GHCUP_INSTALL_BASE_PREFIX $HOME ; set -gx PATH $HOME/.cabal/bin $PATH /home/jason/.ghcup/bin # ghcup-env