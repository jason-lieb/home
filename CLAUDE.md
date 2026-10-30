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

## Git Worktrees

- Default worktree location: `$WORKTREE_ROOT` (falls back to `~/code/.worktrees`), organized as `<location>/<project-name>/<dir>` where `<dir>` is the branch name minus the `jl/` prefix.
- Before creating a worktree, check `git worktree list --porcelain` for an existing registered worktree for the branch — reuse it regardless of location. Never create a location-specific duplicate.
- Worktree logic lives in one POSIX script, `dotfiles/bin/wt` (`wt new|go|rm|open <branch>`), installed to `~/.local/bin/wt` by `dotfiles/install`. It resolves worktrees via the git registry, so it works with worktrees created by any tool at any location.
- A `wt` shell function (`dotfiles/shells/fish/functions/wt.fish`, `dotfiles/shells/posix/functions.sh`) shadows the script only to `cd` into the printed path after `new` and `go`; everything else passes through. Don't add worktree logic to shell configs; change the script instead.
