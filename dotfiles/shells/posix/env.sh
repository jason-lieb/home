# Environment variables
export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR="code"
export PATH="$HOME/.local/bin:$PATH"
if [[ "$(uname)" == "Darwin" ]]; then
    export PATH="$HOME/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
fi

export VAULT_ADDR=https://vault.rg-infra.com

