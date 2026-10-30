# Claude Code Global Instructions

## General

- Be concise. Avoid unnecessary commentary.
- Don't explain changes unless asked.
- DO NOT add comments unless explicitly asked. Never remove existing comments.
- When moving a file, always update all imports to point to the new location. Never leave the original file as a re-export shim.

## Code Style

- Use clear, descriptive names. Avoid abbreviations except well-known ones.
- Prefer functional patterns and immutability where practical.
- Keep functions small and focused on a single responsibility.

## Git Worktrees

- Default worktree location: `$WORKTREE_ROOT` (falls back to `~/code/.worktrees`), organized as `<location>/<project-name>/<dir>` where `<dir>` is the branch name minus the `jl/` prefix.
- Before creating a worktree, check `git worktree list --porcelain` for an existing registered worktree for the branch — reuse it regardless of location. Never create a location-specific duplicate.
