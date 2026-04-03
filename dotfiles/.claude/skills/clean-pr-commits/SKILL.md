---
name: clean-pr-commits
description: Use when a PR branch has messy, incremental, or too many commits and needs to be reorganized into clean logical groupings. Use when the user wants to squash, reorganize, or clean up commits on a branch before merging. Also use when the user says things like "clean up my commits", "reorganize commits", "simplify PR history", or "rewrite commit history".
argument-hint: 'Optional: target branch name (defaults to {current-branch}-clean)'
---

## Clean PR Commits

Reorganize a messy PR branch into clean, logically grouped commits. Creates a new branch with all the same changes but fewer, better-organized commits. Individual commits do not need to compile or pass tests — only the final state matters.

### Step 1 — Validate State

1. Confirm working tree is clean (`git status`). If there are uncommitted changes, stop and ask the user to commit or stash them first.
2. Identify the current branch name. If on `main`, stop — this skill requires being on a feature branch.
3. Confirm there are commits ahead of `main` (`git log --oneline main..HEAD`). If none, stop — nothing to clean.

### Step 2 — Determine Target Branch Name

- If the user provided a branch name argument, use that.
- Otherwise, use `{current-branch}-clean`.
- If the target branch already exists, stop and ask the user whether to delete it or pick a different name.

### Step 3 — Analyze the Changes

Before creating the branch, understand what you're working with:

1. Run `git diff main..HEAD --stat` to see all changed files and their magnitude.
2. Run `git diff main..HEAD` to read the full diff.
3. Run `git log --oneline main..HEAD` to see the original commit messages for context on intent.

Spend time understanding the changes. Group them mentally before proceeding.

### Step 4 — Plan the Commit Groups

Propose a commit plan to the user before making any changes. Present it as a numbered list:

```
Here's how I'd organize the commits:

1. <commit message> — <brief description of what's included>
2. <commit message> — <brief description of what's included>
3. ...
```

**Grouping principles:**

- Group by logical unit of work, not by file
- A refactor that touches 10 files is one commit if it's one logical change
- New feature code and its tests can be separate commits or together — use judgment
- Config/dependency changes that enable a feature can be their own commit
- Deletions/cleanup of old code can be grouped together
- Aim for 2-7 commits for most PRs. Fewer is better if the groupings still make sense.

Wait for user approval or adjustments before proceeding.

### Step 5 — Create the Clean Branch

Default approach — reset to `main` and rebuild all commits from scratch:
```bash
git checkout -b {target-branch}
git reset main
```

This puts you on the new branch with all changes unstaged, ready to be re-committed in clean groups.

**If the user says not to reset main** (e.g., "don't reset main", "keep the first N commits"), it means they want to preserve some existing commits and only reorganize the work after them. In that case, identify the last commit they want to keep, then:
```bash
git checkout -b {target-branch}
git reset {last-commit-to-keep}
```

This preserves the commits up to and including `{last-commit-to-keep}` and unstages everything after it, ready to be re-committed in clean groups.

### Step 6 — Make the Commits

For each planned commit group:

1. Stage the relevant files using `git add <specific-files>`. When a file contains changes belonging to different commits, split it by extracting the relevant hunks into a patch and applying it to the index:
   ```bash
   # Extract specific hunks for this commit
   git diff -- <file> > /tmp/full.patch
   # Edit the patch to keep only the relevant hunks, then:
   git apply --cached /tmp/relevant.patch
   ```
   This lets you stage partial file changes without interactive mode. Don't be afraid to split files across commits when the changes are logically distinct.
2. Commit with a clear message. Use conventional commit format if the repo uses it (check the original commit messages for convention).

**Commit message guidelines:**

- First line: concise summary under 72 characters
- If needed, add a blank line then a body explaining the "why"
- Match the style of existing commits in the repo

**Exclude noise-only changes:** When staging hunks, skip any hunk that consists only of blank line additions/removals or trivial whitespace tweaks with no meaningful content change. These are artifacts of code that was transiently added and removed during development and should not appear in the final commits. If a file's only remaining unstaged changes are such noise, leave it unstaged entirely.

After all commits are made, verify:

```bash
git diff {original-branch}..{target-branch}
```

This diff should be **empty** — the final state must be identical to the original branch. If noise-only changes were excluded, this diff will show those trivial differences; that is acceptable and expected.

### Step 7 — Present Results

Show the user:

1. `git log --oneline main..HEAD` — the new commit history
2. Confirmation that the diff against the original branch is empty

Remind the user:

- The original branch is untouched and can be used as a backup
- If satisfied, they can force-push the clean branch to the PR or rename it
- The original branch can be deleted once they're confident in the result
