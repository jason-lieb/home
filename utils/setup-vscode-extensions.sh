#!/bin/bash

extensions=(
    "albert.TabOut"
    "esbenp.prettier-vscode"
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
