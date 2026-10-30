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

## Git Branches

- Name branches `jl/<short-kebab-case-description>` (e.g. `jl/offboard`, `jl/aa-seed`), branched from `main`.
- Prefer short branch names that are easy to type: ideally one or two words that still clearly describe the change.

## Git Worktrees

- Manage worktrees with `wt`, not `git worktree` directly: `wt new <branch>` creates one in `~/code/.worktrees/<repo>/<branch minus jl/>` (or reuses an existing one anywhere) and prints its path; `wt go <branch>` prints an existing one's path; `wt rm <branch>` removes it; `wt list` lists them. `cd` into the printed path yourself.
