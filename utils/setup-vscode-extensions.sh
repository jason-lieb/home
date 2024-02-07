#!/usr/bin/env bash

extensions=(
    "albert.TabOut"
    "esbenp.prettier-vscode"
    "github.copilot"
    "github.copilot-chat"
    "haskell.haskell"
    "justusadam.language-haskell"
    "mhutchie.git-graph"
    "oderwat.indent-rainbow"
    "PKief.material-icon-theme"
    "SteefH.external-formatters"
)

for extension in "${extensions[@]}"; do
    code --install-extension "$extension"
done
