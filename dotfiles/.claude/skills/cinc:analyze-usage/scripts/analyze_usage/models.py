"""
Shared constants and lookup tables used across modules.
"""
from __future__ import annotations

from pathlib import Path

CLAUDE_DIR = Path.home() / ".claude" / "projects"

EXT_TO_LANG: dict[str, str] = {
    ".py": "Python", ".pyw": "Python",
    ".ts": "TypeScript", ".tsx": "TypeScript",
    ".js": "JavaScript", ".jsx": "JavaScript", ".mjs": "JavaScript", ".cjs": "JavaScript",
    ".rs": "Rust",
    ".go": "Go",
    ".java": "Java",
    ".kt": "Kotlin", ".kts": "Kotlin",
    ".cs": "C#",
    ".cpp": "C++", ".cc": "C++", ".cxx": "C++", ".hpp": "C++",
    ".c": "C", ".h": "C",
    ".rb": "Ruby",
    ".php": "PHP",
    ".swift": "Swift",
    ".sh": "Shell", ".bash": "Shell", ".zsh": "Shell",
    ".md": "Markdown",
    ".json": "JSON",
    ".yaml": "YAML", ".yml": "YAML",
    ".toml": "TOML",
    ".html": "HTML", ".htm": "HTML",
    ".css": "CSS", ".scss": "CSS", ".sass": "CSS",
    ".sql": "SQL",
    ".tf": "Terraform",
    ".r": "R", ".R": "R",
}

WEB_TOOLS: frozenset[str] = frozenset({"WebFetch", "WebSearch"})
TASK_TOOLS: frozenset[str] = frozenset({"TaskCreate", "TaskUpdate", "TaskGet", "TaskList", "TaskOutput", "TaskStop"})
AGENT_TOOLS: frozenset[str] = frozenset({"Agent"})

# Approximate Bedrock rates per 1M tokens. Edit these if your rates differ.
BEDROCK_RATES = {
    "sonnet": {"input": 3.00, "output": 15.00, "cache_write": 0.75, "cache_read": 0.30},
    "opus":   {"input": 5.00, "output": 25.00, "cache_write": 1.25, "cache_read": 0.50},
    "haiku":  {"input": 1.00, "output":  5.00, "cache_write": 0.25, "cache_read": 0.10},
}


def get_bedrock_rates(model: str | None) -> dict:
    """Match a model string to Bedrock rates. Default to Sonnet."""
    if model:
        m = model.lower()
        if "opus" in m:
            return BEDROCK_RATES["opus"]
        if "haiku" in m:
            return BEDROCK_RATES["haiku"]
    return BEDROCK_RATES["sonnet"]


SORT_KEYS: dict = {
    "input":         lambda s: s["input_tokens"],
    "cache_read":    lambda s: s["cache_read_tokens"],
    "output":        lambda s: s["output_tokens"],
    "turns":         lambda s: s["turns"],
    "cost":          lambda s: s["cost_usd"] if s.get("cost_usd") is not None else (s.get("est_cost_usd") or 0),
    "user_messages": lambda s: s["user_messages"] if s.get("user_messages") is not None else 0,
    "duration":      lambda s: s["duration_min"] if s.get("duration_min") is not None else 0,
    "tools":         lambda s: sum((s.get("tool_usage_summary") or {}).values()),
}
