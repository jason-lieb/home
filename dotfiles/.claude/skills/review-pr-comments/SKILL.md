---
name: review-pr-comments
description: Use when the user wants to review, triage, or act on PR review comments. Triggers on phrases like "review comments on my PR", "what do reviewers think", "handle PR feedback", "address review comments", "what's left to fix on this PR", "respond to PR comments", or any time the user wants to understand or act on code review feedback on the current branch.
---

Fetch all review comments on the current branch's PR, evaluate AI-generated ones for validity and relevance, then produce a concise fix plan.

## Step 1 — Find the PR

Run `gh pr view --json number,title,headRefName,baseRefName,url` to confirm a PR exists for the current branch. If none exists, stop and tell the user.

## Step 2 — Fetch All Review Comments

Fetch both types of comments:

```bash
# Inline code review comments (on specific lines)
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --paginate

# Top-level PR review thread comments
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews --paginate
```

Get `{owner}/{repo}` from `gh repo view --json nameWithOwner`.

For each comment, note:
- **author**: the username
- **body**: comment text
- **path** + **line**: file and line (for inline comments)
- **state**: for review-level comments (APPROVED, CHANGES_REQUESTED, COMMENTED)

Discard purely automated bot notifications (CI status, deploy previews). Keep all substantive review comments.

## Step 3 — Classify Commenters

Separate comments into two buckets:

**Human reviewers** — anyone who is not a known AI reviewer. Trust their comments at face value.

**AI reviewers** — accounts that are AI-generated review tools. Common indicators:
- Username contains: `copilot`, `claude`, `coderabbit`, `github-advanced-security`, or similar bot suffixes
- Comment footer identifies it as AI-generated (e.g., "Generated with Claude Code", "Copilot code review")

When in doubt about whether a commenter is human or AI, treat them as human.

## Step 4 — Evaluate AI Comments

For each AI comment, judge two things:

1. **Relevance** — Is this comment about code that was actually changed in this PR? AI reviewers sometimes flag pre-existing issues or adjacent code. Check the PR diff (`gh pr diff`) to confirm the flagged lines are part of the change.

2. **Validity** — Is the concern real? Read the flagged code in context. Would a thoughtful senior engineer agree this is a problem? Consider:
   - Is it a genuine bug or correctness issue?
   - Is it a real style/convention violation (not a false positive)?
   - Is it already handled elsewhere (intentional pattern, tested behavior, explained by a comment)?

Classify each AI comment as:
- **Valid** — relevant to the PR and raises a real concern worth addressing
- **Skippable** — not relevant to this PR's changes, or a false positive / nitpick not worth acting on

Note your reasoning briefly (one sentence) for each skippable comment so the user can override your judgment.

## Step 5 — Produce the Fix Plan

Output a concise plan in this format:

---

### Fix Plan

**From human reviewers:**

For each human comment, summarize what they're asking for and what to do. If one reviewer left multiple related comments, consolidate into one action item.

- [ ] **@username** — `path/to/file:line` — _brief description of what to change_

**From AI reviewers (valid concerns):**

List only AI comments you judged as valid.

- [ ] **@ai-reviewer** — `path/to/file:line` — _brief description of what to change_

**AI comments skipped:**

- **@ai-reviewer** — `path/to/file:line` — skipped: _reason (e.g., "flags pre-existing code not changed in this PR", "false positive — pattern is intentional")_

---

If there are no comments, say so. If all AI comments were skipped and there are no human comments, say that rather than producing an empty plan.

## Tips

- One bullet per addressable concern, not one per comment. Merge related comments from the same reviewer.
- Use `gh pr diff` to read the actual diff when you need context to evaluate a comment.
- Keep reasoning for skipped comments short — the user just needs enough to agree or override.