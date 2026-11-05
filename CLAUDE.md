# Claude Code Instructions

## IMPORTANT
This is a multi-machine multi-os setup. When working on any machine, always be aware of which machine and OS you are on.

## Shell Configs

Shell configs live in `dotfiles/shells/`. When updating any shell config, ensure the change is applied to all relevant shells.

## Keeping CLAUDE.md Updated

When making changes that affect file structure, paths, or conventions referenced in this file, update CLAUDE.md to reflect the new state.

## Dotfiles

Config files (git, shell, Claude settings, etc.) are managed in `dotfiles/`. When modifying any config, always look for and edit the dotfiles-managed version first, never the installed copy directly (e.g., edit `dotfiles/.claude/settings.json`, not `~/.claude/settings.json`).

## Install Scripts

All install scripts must be idempotent — running them multiple times should produce the same result without errors or unintended side effects.
