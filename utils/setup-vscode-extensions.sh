#!/usr/bin/env bash

extensions=(
    "albert.TabOut"
    "esbenp.prettier-vscode"
    "github.vscode-github-actions"
    "github.copilot"
    "github.copilot-chat"
    "haskell.haskell"
    "justusadam.language-haskell"
    "mhutchie.git-graph"
    "ms-vscode.makefile-tools"
    "oderwat.indent-rainbow"
    "PKief.material-icon-theme"
    "SteefH.external-formatters"
    "YoavBls.pretty-ts-errors"
)

for extension in "${extensions[@]}"; do
    code --install-extension "$extension"
done
