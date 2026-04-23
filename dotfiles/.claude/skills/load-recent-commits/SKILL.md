---
name: load-recent-commits
description: Use when the user wants to load, review, or understand the last N commits. Triggers on phrases like "load the last N commits", "show me the last N commits", "bring in recent commit history", "load commit context", or any time the user wants recent git commit history loaded into context.
---

Load the last N commits into context for review or reference.

## Step 1 — Determine N

If the user provided a number, use it. If not, ask: "How many commits would you like to load?"

## Step 2 — Load commit history

Run the following to get a structured view of the last N commits:

```bash
git log -N --pretty=format:"%H %s" --name-status
```

This gives:
- Full commit hash + subject line
- Files changed per commit (added/modified/deleted)

## Step 3 — Load each commit's full diff

For richer context (actual code changes), run per commit:

```bash
git show --stat --patch <hash>
```

Or load all N commits at once:

```bash
git log -N -p --stat
```

## Step 4 — Summarize what was loaded

After loading, tell the user:
- How many commits were loaded
- The date range (oldest → newest)
- A brief one-line summary of each commit

## Notes

- If N is large (> 20), warn the user this may consume significant context before proceeding
- If not in a git repo, say so and stop
- Use `git log --oneline -N` first for a quick preview if N > 10, then confirm before loading full diffs
