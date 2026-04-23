---
name: suggest-new-skills
description: Use when the user wants to discover new skills to create based on past AI chat history, find patterns in past sessions, identify gaps in skill coverage, or get recommendations for skills that don't exist yet. Triggers on phrases like "what skills should I create", "find patterns in my chats", "what am I doing without a skill", "skill gap analysis", or "suggest new skills".
---

Analyze past AI chat sessions to find recurring task patterns and recommend new skills.

## Step 1 — Extract chat history

Run the extraction script (located alongside this skill):

```bash
~/.claude/skills/suggest-new-skills/extract-chats.sh
```

Optional: pass `--limit N` to control how many sessions to analyze (default: 50).

The script outputs conversation summaries from both Claude Code and opencode, each annotated with which skills (if any) were loaded during that session.

## Step 2 — Dispatch analysis subagent

Dispatch a subagent with the full script output and this prompt:

> You are analyzing AI chat history to recommend new skills. A "skill" is a reusable, named workflow or technique that an AI agent can load on-demand to handle a specific recurring task.
>
> The data below contains summaries of past conversations. Each entry shows: the source tool (claude-code or opencode), the user's requests, and which skills (if any) were loaded.
>
> Your job:
> 1. Identify recurring task types across sessions
> 2. Flag which task types had NO skill loaded (or no obviously relevant skill)
> 3. Group patterns by theme (e.g. debugging, code review, git, documentation, refactoring)
> 4. Recommend 3–7 candidate skills. For each, provide:
>    - Suggested skill name (hyphenated, verb-first, e.g. `analyzing-bundle-size`)
>    - One sentence: what task it handles
>    - 2-3 example user requests that would trigger it
>    - Estimated frequency: how often this pattern appeared
>
> Focus especially on gaps: tasks done repeatedly with no skill loaded.
>
> [PASTE SCRIPT OUTPUT HERE]

## Step 3 — Print recommendations

Return the subagent's output directly to the terminal. Present each recommended skill clearly so the user can decide which to create.

## Notes

- If the extraction script fails for one tool (e.g. opencode DB not found), it will skip that source and note it — results will just cover the available source
- If no patterns are found (too few sessions), say so and suggest running with a larger `--limit`
- After presenting recommendations, offer to invoke the `brainstorming` skill to design any of the suggested skills
