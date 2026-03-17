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

export VAULT_ADDR=https://vault.rg-infra.com

