---
name: analyze-usage
description: >
  Analyze Claude Code and OpenCode token usage from local session logs.
  Use this skill whenever a user asks about their Claude usage, token costs, expensive sessions,
  what caused high spend, why tokens are so high, usage patterns, or wants to investigate a
  specific session. Also triggers on questions like "show me my usage", "what was I working on",
  "why did that cost so much", "did I use compact", or "how many tokens did I use".
triggers:
  - /analyze-usage
  - show my usage
  - analyze my usage
  - token usage
  - why is my usage so high
  - expensive session
  - how much did I use
---

# Analyze Usage

Help the user understand their Claude Code and/or OpenCode token usage by running the analysis
script, interpreting the results, surfacing patterns, and answering follow-up questions.

## Step 1: Run the script

The analysis script ships with the plugin. Locate it with:

```bash
SCRIPT=$(find ~/.claude/plugins/cache -name "analyze-usage.py" -path "*/analyze-usage/scripts/*" 2>/dev/null | sort -Vr | head -1)
```

It reads from `~/.claude/projects/` (Claude Code) and/or the OpenCode SQLite database —
the working directory doesn't matter.

### Choose the right command based on what the user asked

**General usage overview / "show my usage" / no specific timeframe mentioned:**
```bash
python3 "$SCRIPT" --json --period 30d --top 20
```
Default to the last 30 days — it's the most consistently useful window. `--period month` starts over on the 1st; `--period 30d` is always a rolling window.

**"This week" / "today" / "recently":**
```bash
python3 "$SCRIPT" --json --period week --top 20
python3 "$SCRIPT" --json --date YYYY-MM-DD --top 20   # for "today" or a specific date
```

**"All time" / "ever" / "total":**
```bash
python3 "$SCRIPT" --json --top 20
```

**Guarantee sessions from both sources (default: top 20 + at least 5 per source):**
```bash
python3 "$SCRIPT" --json --top 20                        # default: floor of 5 per source when both present
python3 "$SCRIPT" --json --top 20 --min-per-source 10    # guarantee at least 10 from each source
python3 "$SCRIPT" --json --top 20 --min-per-source 0     # disable floor, strict top N only
```

**Explicit date range:**
```bash
python3 "$SCRIPT" --json --since 2026-03-01 --until 2026-03-15 --top 20
python3 "$SCRIPT" --json --since 2026-03-10 --top 20   # open-ended
```

**"What did I work on?" / activity summary / by day:**
```bash
python3 "$SCRIPT" --daily --period 30d
```
Use `--daily` when the user wants to understand their activity pattern over time, not just the heaviest sessions.

**"What tools do I use?" / tool analysis / agent loop detection:**
```bash
python3 "$SCRIPT" --tools --period 30d
```

**"Which project cost the most?" / by-project totals:**
```bash
python3 "$SCRIPT" --period 30d --summary
```
`--summary` gives rolled-up totals per project plus tool and language breakdowns — better than a session list for project-level questions.

**Focus on real work (exclude quick test sessions):**
```bash
python3 "$SCRIPT" --json --period 30d --filter --top 20
```
Add `--filter` when the user wants to understand meaningful sessions, not throwaway ones.

**Specific source only:**
```bash
python3 "$SCRIPT" --json --period 30d --source claude-code
python3 "$SCRIPT" --json --period 30d --source opencode
```

**Sort by a different field (default: input tokens):**
```bash
python3 "$SCRIPT" --json --period 30d --sort cache_read --top 10
# Sort options: input, cache_read, output, turns, cost, user_messages, duration, tools
```

**Drill into a specific session:**
```bash
python3 "$SCRIPT" --json --session <session-id>
```

**Open a session transcript as HTML (claude-code sessions only, requires `uvx` or `uv`):**
```bash
python3 "$SCRIPT" --transcript --session <session-id>
```

Run the `find` command first, then the script command, with the Bash tool. Capture the JSON output.

## Step 2: Interpret the data

Once you have the JSON, give the user a clear, plain-language summary. Don't just repeat
the numbers — explain what they mean. Structure your response:

### Summary section

**Session totals** — Use `metadata.sessions_by_source` for true per-source counts (e.g. "526 Claude Code sessions, 20 OpenCode sessions"). Never use the length of the `sessions` array for totals.

**Top-10 ranked table** — Always render this exact table with these exact columns (no substitutions, no omissions):

| # | Date | Title | Project | Branch | Turns | Total Tokens | Input Tokens | Est. Cost | Tool |
|---|------|-------|---------|--------|-------|-------------|-------------|-----------|------|

Column rules:
- `#` — rank 1–10
- `Date` — `YYYY-MM-DD` from session start
- `Title` — truncate to ~40 chars with `…` if longer
- `Project` — last path component of the project directory (e.g. `my-repo`); `—` if absent
- `Branch` — `git_branch` value for claude-code sessions; `—` for OpenCode or if absent
- `Turns` — turn count as integer
- `Total Tokens` — `total_tokens` formatted with units (e.g. `39.9M`, `1.2M`, `450K`)
- `Input Tokens` — `input_tokens` formatted with units
- `Est. Cost` — for `opencode` sessions: `cost_usd` → `$X.XX`; for `claude-code` sessions: `est_cost_usd` → `~$X.XX`; if neither field present: `—`
- `Tool` — `"Claude Code"` or `"OpenCode"` from the `source` field

**Transcript reference block** — After the table, if any `claude-code` sessions in the top 10 have a `transcript_cmd` field, output a compact numbered reference block (keyed to rank #). Group all commands together — do NOT scatter them inside the table or in separate shell blocks.

For each session, render:
- The `transcript_link` value (an OSC 8 hyperlink — output it verbatim as-is, including the ANSI escape sequences; terminals that support OSC 8 will render it as a clickable `[open transcript]` link)
- Followed on the same line by a space and the `transcript_cmd` value in backticks (so the command is always visible as fallback)

Example format:

```
Transcripts (Claude Code sessions):
  [1] <transcript_link value> `<transcript_cmd value>`
  [3] <transcript_link value> `<transcript_cmd value>`
```

Omit this block entirely if no claude-code sessions with `transcript_cmd` appear in the top 10.

**Top 5 Most Expensive Days** — from `metadata.daily_totals` (aggregated across ALL sessions, not just the top 10):

| # | Date | Sessions | Turns | Total Tokens | Input Tokens | Est. Cost |
|---|------|----------|-------|-------------|-------------|-----------|

Column rules:
- `#` — rank 1–5
- `Date` — `YYYY-MM-DD`
- `Sessions` — number of sessions that day
- `Turns` — total turns across all sessions
- `Total Tokens` / `Input Tokens` — formatted with units
- `Est. Cost` — `$X.XX` from the `cost` field

This table helps surface days where many smaller sessions added up to more than any single large session. If the top day doesn't appear in the top-10 sessions table, call that out.

**Overall pattern** — 1–2 sentences after the table (e.g. "Most usage is concentrated in 2 sessions", "Cache read is driving the majority of cost").

**Activity context** — If `languages` or `features_used` data is present, briefly note what the user was working on (e.g. "Mostly Python and TypeScript work", "3 sessions used MCP tools").

### Patterns to flag proactively

Look for these and call them out if present:

**Context compounding** — if `input_tokens` grows steadily across turns within a session,
that's normal context accumulation. If it's high (e.g. 50k+ cumulative input in one session),
explain that every turn re-sends the full conversation history.

**High cache_read_tokens** — on Bedrock, cache reads are billed at ~10% of the normal input
rate. A session with 10M cache_read tokens is still significant cost. Flag sessions where
`cache_read_tokens` dwarfs `input_tokens`.

**Large file reads** (`large_read_events`) — turns where a big chunk was written to the
prompt cache. This usually means Claude read a large file or web page into context. Once
that content is in context, it gets re-sent (from cache) on every subsequent turn.

**Context spikes** (`context_spikes`) — a sudden jump in `input_tokens` on a single turn,
meaning a large tool result (file content, command output, API response) was injected.

**Compaction** (`compaction_events`) — `/compact` or `/auto-compact` was used. Check the
`auto` field: `auto: true` means the context window filled up and triggered compaction
automatically — more concerning than a manual `/compact` because the session had already
accumulated maximum context before it fired. Compaction resets the input token count
significantly on the next turn.

**Long sessions with many turns** — a 100+ turn session will compound costs heavily even
if individual turns are small. Each turn re-sends everything.

**Agent/subagent work** — multiple sessions in the same project at the same time, or
sessions with very high turn counts relative to their duration, can indicate agent loops
spinning through many parallel tasks.

**High tool call counts** (`tool_usage_summary`) — unusually high counts for a single tool
(especially `Bash` or `Edit`) can indicate agent loops. Flag sessions where total tool calls
greatly exceed the turn count (ratio > 5x is a strong signal). Use `--tools` to see this
analysis across all sessions at once.

**Agent detection** — a session with low `user_messages` but high `turns` is likely an agent
loop (Claude autonomously calling tools with no human input). Low `user_messages` combined
with `features_used` containing `"agents"` confirms subagent orchestration.

**Language context** — `languages` shows which programming languages Claude was working with
in a session, inferred from file path arguments to tool calls. Useful for understanding
project context when the `cwd` alone isn't descriptive.

**Git activity** — `git_activity` counts specific git operations Claude ran via Bash. High
`commit` counts indicate productive coding sessions; high `checkout`/`branch` counts may
indicate branching workflows or context switching.

**Reasoning tokens** (`reasoning_tokens`, OpenCode only) — high reasoning token counts
(e.g. >10k per turn) mean extended thinking mode was active. These are billed at the
standard output rate and can significantly increase costs.

**Actual dollar costs** (`cost_usd`) — OpenCode tracks real per-message costs. Surface these directly. If a session shows a high `cost_usd`, call it out explicitly.

**Estimated costs** (`est_cost_usd`, Claude Code only) — Claude Code sessions now include a cost estimate computed from hardcoded Bedrock rates (Sonnet: $3/$15 per 1M in/out; Opus: $5/$25; Haiku: $1/$5; cache write: ~25% of input rate; cache read: ~10%). These are estimates — actual AWS billing may differ by region or negotiated rate. Displayed with a `~` prefix.

## Step 3: Answer follow-up questions

The user may want to dig deeper. Common questions and how to handle them:

- *"Why was [date] expensive?"* / *"What drove cost on [date]?"* — Re-run with `--date YYYY-MM-DD --json --top 20 --sort cost` to list all sessions that day ranked by cost. Then run `--session <id>` on the top 1–2 to see the per-turn breakdown. For claude-code sessions, `--transcript --session <id>` opens the full conversation. Chain these commands — don't ask the user to re-run manually.

- *"Why is my Claude Code usage high?"* / *"Break down by source"* — When OpenCode sessions dominate the summary or daily table but the user's question is specifically about Claude Code (or vice versa), re-run with `--source claude-code` (or `--source opencode`) to filter to that source only. This avoids OpenCode's no-cache cost profile skewing the picture when the user wants to understand a specific tool.

- *"Which session cost the most?"* — Use `--sort cost` to rank by cost. For OpenCode sessions, this uses `cost_usd` directly. For Claude Code sessions, it uses `est_cost_usd` (estimated from Bedrock rates). Exact AWS billing may differ.

- *"What was I doing in that session?"* — Look at `cwd` (the project directory), `last_prompt`
  (the final thing the user typed), and `duration_min`. Together these tell a story.

- *"Did compaction help?"* — Compare turn count and `input_tokens` before vs. after
  `compaction_events`. A successful compact should show a drop in per-turn input on subsequent turns.

- *"Why is input 97% of my tokens?"* — This is expected with Claude Code. Output is small
  (code edits, responses). Input is large because the entire conversation history + file contents
  re-sent each turn.

- *"How can I reduce usage?"* — Suggest:
  1. Use `/compact` earlier in long sessions (before context gets huge)
  2. Start new sessions for new tasks rather than continuing long ones
  3. Avoid reading very large files unnecessarily (summarize or grep instead)
  4. Use `--top 5` or date filters to focus on specific problem sessions

- *"Can I see the full conversation?"* — For claude-code sessions, use the `transcript_cmd` value from the session data directly — paste it into a terminal. Or run:
  ```bash
  uvx claude-code-transcripts json ~/.claude/projects/<project>/<session-id>.jsonl --open
  ```
  This requires `uvx` or `uv` to be installed (`pip install uv` or `brew install uv`). Only works for claude-code source sessions, not OpenCode.

## Step 4: Proactively share usage tips

After presenting the data, share relevant lessons learned based on what you see in the session stats. Tailor the advice to the user's actual patterns.

**Cache expiry is the biggest cost driver.** If a user went idle for 30+ minutes and then continued a session, the entire context was re-cached at full creation rate (~25%) on the next turn — erasing all the savings from cache reads. A 38-minute idle break is enough to expire the cache.

**Cache reads aren't free.** At ~10% of the input rate on Bedrock, a session with 10M cache_read_tokens is still significant. High cache read volume at scale adds up.

**300+ turn sessions are a smell.** Very long sessions indicate the user kept working in the same context far past the point where a fresh session would have been cheaper and cleaner. Each turn re-sends everything.

**Rapid-fire tool loops inflate context early.** When Claude runs many tool calls in a row (e.g. read → edit → read → edit), each turn adds more content to the context. Starting the next task fresh is cheaper than continuing.

**OpenCode vs Claude Code have different cost profiles.** OpenCode tracks actual cost per message (`cost_usd`). Claude Code sessions now include `est_cost_usd` — an estimate from hardcoded Bedrock rates. For exact billing, check AWS Cost Explorer.

**Practical habits to recommend:**

- **Start a new session for each distinct task** — fresh context beats compacted context every time. Carrying completed task context wastes tokens on every subsequent turn.
- **Start fresh after idle time** — if a user steps away for 30+ minutes, resuming the same session means the entire context gets re-cached at full rate. Better to start a new session.
- **Avoid reading large files unless needed throughout the session** — a large file read early in a session adds to every subsequent turn's context.
- **If auto-compact fired, that session should have been split earlier** — `auto: true` in `compaction_events` means the context window filled up completely. This is a sign the session ran too long on one task.
- **Prefer fresh sessions over `/compact`** — `/compact` helps in a pinch, but compacted context still carries overhead. A truly fresh session starts lighter.

## Step 5: Mention /insights for complementary stats

After the analysis, mention Claude Code's built-in `/insights` command as a complementary tool:

> Claude Code also has a built-in `/insights` command that gives qualitative patterns and workflow recommendations based on your session history. It's complementary to this analysis: `/insights` focuses on *how* you're working (patterns, habits, workflow suggestions), while `analyze-usage` focuses on *what it cost* (token counts, cache breakdown, per-turn detail). If you haven't tried `/insights`, it's worth running.

Only mention this once per conversation, and only if it's relevant to the user's question.

## Data reference

Key fields in the JSON output:

| Field | What it means | Sources |
|---|---|---|
| `input_tokens` | Tokens sent to the model (billed at full rate) | both |
| `output_tokens` | Tokens generated by the model (billed at full rate) | both |
| `cache_creation_tokens` | New tokens written to prompt cache (~25% rate on Bedrock) | both |
| `cache_read_tokens` | Tokens served from existing cache (~10% rate on Bedrock) | both |
| `reasoning_tokens` | Tokens used for extended thinking (billed at output rate) | opencode |
| `cost_usd` | Actual dollar cost for the session | opencode |
| `est_cost_usd` | Estimated cost from hardcoded Bedrock rates (displayed with `~` prefix) | claude-code |
| `compaction_events` | `/compact` or `/auto-compact` commands; includes `auto` flag | both |
| `large_read_events` | Turns where >5k new tokens were cached (file/doc read into context) | both |
| `context_spikes` | Turns where input grew >20k (large tool result injected) | both |
| `tool_usage_summary` | Count of tool calls by tool name (e.g. `{Bash: 35, Read: 12}`) | both |
| `user_messages` | Number of human text messages (excludes automated tool_result messages) | both |
| `title` | Session title from `custom-title` or `agent-name` messages | both |
| `languages` | Programming languages detected from file paths in tool calls (e.g. `{Python: 12, TypeScript: 8}`) | both |
| `features_used` | Features detected: `mcp`, `web`, `tasks`, `agents` | both |
| `git_activity` | Git operations run via Bash (e.g. `{commit: 3, push: 1}`) | both |
| `git_branch` | Branch active during the session (most common value if branch changed mid-session) | claude-code |
| `git_branches` | All branches seen mid-session (only present if the branch changed) | claude-code |
| `last_prompt` | The last thing the user typed in this session | both |
| `duration_min` | Wall-clock minutes from first to last message | both |
| `turns` | Number of complete request/response cycles | both |
| `source` | Data source: `"claude-code"` or `"opencode"` | both |
| `transcript_cmd` | Ready-to-run `uvx claude-code-transcripts` command to open the session as HTML — paste into a terminal | claude-code |
| `transcript_link` | OSC 8 hyperlink ANSI escape sequence — output verbatim; terminals that support OSC 8 render it as a clickable `[open transcript]` link pointing to the session's JSONL file | claude-code |

**Transcript flag:** `--transcript --session <id>` opens the session as an HTML file in the browser using `uvx` (or `uv tool run` if `uvx` is not found). Only works for `claude-code` source sessions (not OpenCode). Requires `uv` or `uvx` to be installed.

**JSON output format:** `--json` returns an envelope `{"metadata": {...}, "sessions": [...]}`. Use `metadata.sessions_by_source` for true per-source totals. The `sessions` array contains only the selected/displayed sessions.

## Notes on Bedrock

For Claude Code sessions, `cost_usd` is null but `est_cost_usd` is computed automatically using hardcoded Bedrock rates:

| Tier | Input/1M | Output/1M | Cache Write/1M | Cache Read/1M |
|---|---|---|---|---|
| Sonnet | $3.00 | $15.00 | $0.75 | $0.30 |
| Opus | $5.00 | $25.00 | $1.25 | $0.50 |
| Haiku | $1.00 | $5.00 | $0.25 | $0.10 |

Cache write rate reflects ~25% of input (discounted Bedrock rate). These are estimates — actual AWS billing may differ by region or negotiated rate. To edit rates, update `BEDROCK_RATES` in `scripts/analyze_usage/models.py`.

For OpenCode users, `cost_usd` is populated from OpenCode's own cost tracking. The actual cost depends on the configured provider — Bedrock users may see null here too if the provider doesn't report costs.
