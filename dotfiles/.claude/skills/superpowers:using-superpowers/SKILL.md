---
name: using-superpowers
description: Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If the user explicitly requests a skill (by name or by describing its purpose), invoke it immediately.

If you think a skill might apply but the user has NOT explicitly requested it, you MUST ask the user first before invoking it. Do not invoke skills proactively without user confirmation.
</EXTREMELY-IMPORTANT>

## Instruction Priority

Superpowers skills override default system prompt behavior, but **user instructions always take precedence**:

1. **User's explicit instructions** (CLAUDE.md, GEMINI.md, AGENTS.md, direct requests) — highest priority
2. **Superpowers skills** — override default system behavior where they conflict
3. **Default system prompt** — lowest priority

If CLAUDE.md, GEMINI.md, or AGENTS.md says "don't do X" and a skill says "always do X," follow the user's instructions. The user is in control.

## How to Access Skills

Use the `Skill` tool. When you invoke a skill, its content is loaded and presented to you—follow it directly. Never use the Read tool on skill files.

# Using Skills

## The Rule

**If the user explicitly requests a skill, invoke it BEFORE any response or action.** If a skill seems relevant but was not requested, ask the user whether to use it before proceeding.

```dot
digraph skill_flow {
    "User message received" [shape=doublecircle];
    "Skill explicitly requested?" [shape=diamond];
    "Invoke Skill tool" [shape=box];
    "Skill might apply?" [shape=diamond];
    "Ask user: use [skill]?" [shape=box];
    "User says yes?" [shape=diamond];
    "Announce: 'Using [skill] to [purpose]'" [shape=box];
    "Has checklist?" [shape=diamond];
    "Create TodoWrite todo per item" [shape=box];
    "Follow skill exactly" [shape=box];
    "Respond (including clarifications)" [shape=doublecircle];

    "User message received" -> "Skill explicitly requested?";
    "Skill explicitly requested?" -> "Invoke Skill tool" [label="yes"];
    "Skill explicitly requested?" -> "Skill might apply?" [label="no"];
    "Skill might apply?" -> "Ask user: use [skill]?" [label="yes"];
    "Skill might apply?" -> "Respond (including clarifications)" [label="no"];
    "Ask user: use [skill]?" -> "User says yes?";
    "User says yes?" -> "Invoke Skill tool" [label="yes"];
    "User says yes?" -> "Respond (including clarifications)" [label="no"];
    "Invoke Skill tool" -> "Announce: 'Using [skill] to [purpose]'";
    "Announce: 'Using [skill] to [purpose]'" -> "Has checklist?";
    "Has checklist?" -> "Create TodoWrite todo per item" [label="yes"];
    "Has checklist?" -> "Follow skill exactly" [label="no"];
    "Create TodoWrite todo per item" -> "Follow skill exactly";
}
```

## Skill Priority

When multiple skills could apply, use this order:

1. **Process skills first** (brainstorming, debugging) - these determine HOW to approach the task
2. **Implementation skills second** (frontend-design, mcp-builder) - these guide execution

"Let's build X" → brainstorming first, then implementation skills.
"Fix this bug" → debugging first, then domain-specific skills.

## Skill Types

**Rigid** (debugging): Follow exactly. Don't adapt away discipline.

**Flexible** (patterns): Adapt principles to context.

The skill itself tells you which.

## User Instructions

Instructions say WHAT, not HOW. "Add X" or "Fix Y" doesn't mean skip workflows.
