# Claude Code Instructions

## Shell Configs

Shell configs live in `dotfiles/shells/`. When updating any shell config (`.bashrc`, `.zshrc`, `config.fish`), ensure the change is applied to all shells. Shared config belongs in `dotfiles/shells/aliases.sh` (fish + posix) or `dotfiles/shells/posix/env.sh` (bash + zsh).

## Install Scripts

All install scripts must be idempotent — running them multiple times should produce the same result without errors or unintended side effects.
