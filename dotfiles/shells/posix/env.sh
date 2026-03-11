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

if [[ "$(uname)" == "Darwin" ]]; then
    export PNPM_HOME="$HOME/Library/pnpm"
else
    export PNPM_HOME="$HOME/.local/share/pnpm"
fi
case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
esac
