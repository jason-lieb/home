---
name: run-to-completion
description: Use when the user wants you to stop pausing mid-task to ask clarifying questions and instead continue autonomously to full task completion. Triggers on phrases like "run to completion", "don't ask questions", "just do it", "stop asking", "keep going", "no more questions", or "autonomous mode".
---

# Run to Completion

## Overview

When activated, you complete the task without stopping to ask the user questions. Make decisions using context from the codebase and reasonable defaults. Report decisions made at the end.

## The Rule

**Do not ask the user any questions until the task is fully complete.**

This is not a suggestion. When the user invokes this skill, they have explicitly opted out of mid-task check-ins. Honor that.

## What Changes

| Normally | Run-to-completion |
|----------|------------------|
| Stop and ask about ambiguous scope | Infer from codebase patterns, pick the conservative interpretation |
| Ask about architectural choices | Pick the simpler/safer/more reversible option |
| Ask for confirmation before continuing | Continue |
| Present options and ask user to choose | Choose the safest option, note alternatives in final report |
| Stop when user is unavailable | Continue — that's the point |

## How to Handle Ambiguity

**Scope ambiguity** ("clean up the shell configs"):
- Infer from codebase what's clearly intended
- Do the most conservative interpretation
- Do NOT do irreversible or sweeping changes without explicit instruction

**Architectural decisions** (CSS classes vs inline styles, approach A vs B):
- Pick the safer, more reversible option
- Note what you chose and why in your final report

**Risky/irreversible operations** (DB migrations, destructive refactors):
- Use the safe/reversible approach if one exists
- If both options are risky or irreversible, STOP and ask — this is the one exception (see below)

## The One Exception

**Stop if continuing would cause irreversible harm with no safe path.**

This means: data loss, production breakage with no rollback, security exposure. 

NOT an exception:
- "I'm not sure which approach is better"
- "The user might not like this"
- "There are two reasonable options"
- "This feels like a big change"

If you find yourself wanting to stop and ask, first ask: "Is there a safe/reversible option I can take instead?" If yes — take it and continue.

## At Task Completion

Summarize what you did, including:
- Key decisions made and why
- Alternatives you considered but didn't take
- Anything the user should review or may want to change

## Red Flags — Stop Rationalizing

If you're thinking any of these, you're rationalizing stopping:

| Thought | Reality |
|---------|---------|
| "I don't know which approach the user prefers" | Pick the safer one and note it |
| "This feels like an important architectural decision" | Note it in the report, keep going |
| "The user would probably want to weigh in here" | They opted out of that by invoking this skill |
| "I should confirm before I do something big" | No. Continue. Report at the end. |
| "The scope is ambiguous" | Infer from context, pick conservative, continue |
| "I'll just ask one quick question" | No. Complete the task first. |

## Violation Examples

**Violation:**
```
I've implemented the ThemeContext. Before I update the components, should I use 
CSS classes or inline styles?
```

**Compliant:**
```
[continues updating components using CSS classes as the cleaner/reversible approach]
[at end]: Used CSS classes rather than inline style overrides for the remaining 6 
components — easier to maintain and revert. Let me know if you'd prefer inline styles.
```
