---
name: open-files
description: Use when the user wants to open files associated with a PR, branch, commit, or unit of code in their editor. Triggers on phrases like "open the files from this PR", "open files changed in this commit", "open all files on this branch", "open the files for PR #123", or any time the user wants to open a set of code files in VS Code based on a git reference.
---

Open the files changed in a given PR, branch, or commit using `code` (VS Code).

## Step 1 — Resolve the target

Determine what git reference the user gave you:

- **PR number** (e.g. `#123`, `123`): Get changed files with `gh pr diff --name-only <number>`
- **Branch name** (e.g. `feat/my-feature`): Get files changed relative to the merge base with `git diff --name-only $(git merge-base HEAD <branch>) <branch>`
- **Commit hash or ref** (e.g. `abc1234`, `HEAD~2`): Get files with `git diff-tree --no-commit-id -r --name-only <ref>`
- **Current branch / "this PR"**: Run `gh pr diff --name-only` (no args) — falls back to `git diff --name-only main...HEAD` if no PR exists
- **Vague reference** (e.g. "these changes", "the current work"): Use the current branch against main: `git diff --name-only main...HEAD`

Deduplicate the file list. **Before building the command, check each file exists on disk** — deleted files will appear in git diffs but can't be opened. Use the Read tool to attempt reading each file; if it returns an error, the file doesn't exist — silently drop it. Only pass files that are actually present.

## Step 2 — Print and run the commands

Print one `code` invocation per file (so each line is copyable individually), then run a single `code` call with all files as arguments:

```
code 'src/foo.ts'
code 'src/bar.ts'
code 'tests/foo.test.ts'
```

```bash
code 'src/foo.ts' 'src/bar.ts' 'tests/foo.test.ts'
```

## Notes

- If no files are found, say so and stop — don't run an empty `code` command.
- If there are more than 20 files, warn the user before opening them all.
- Always use single-quoted paths to handle spaces and special characters.
