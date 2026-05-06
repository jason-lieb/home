"""
Shared utility functions used across source loaders.
"""
from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path

from .models import EXT_TO_LANG, WEB_TOOLS, TASK_TOOLS, AGENT_TOOLS


def _detect_github_repo(cwd: str | None) -> str | None:
    """Return 'owner/repo' if cwd is inside a GitHub-hosted git repo, else None."""
    if not cwd or not Path(cwd).is_dir():
        return None
    try:
        remote = subprocess.check_output(
            ["git", "remote", "get-url", "origin"],
            cwd=cwd,
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip().rstrip("/")
        m = re.search(r"github\.com[:/](.+?)(?:\.git)?$", remote)
        if m:
            repo = m.group(1)
            if re.fullmatch(r"[^/]+/[^/]+", repo):
                return repo
    except (subprocess.CalledProcessError, FileNotFoundError, OSError):
        pass
    return None


def _extract_file_lang(path_str: str) -> str | None:
    if not path_str or not isinstance(path_str, str):
        return None
    ext = os.path.splitext(path_str)[1].lower()
    return EXT_TO_LANG.get(ext)


def _detect_features(tool_name: str, features: set) -> None:
    if tool_name.startswith("mcp__"):
        features.add("mcp")
    elif tool_name in WEB_TOOLS:
        features.add("web")
    elif tool_name in TASK_TOOLS:
        features.add("tasks")
    elif tool_name in AGENT_TOOLS:
        features.add("agents")


def _detect_git(cmd_str: str, git_activity: dict) -> None:
    if not cmd_str:
        return
    m = re.search(
        r"\bgit\s+(commit|push|pull|merge|rebase|checkout|branch|fetch|reset|stash|tag|cherry-pick|diff|log|status)\b",
        cmd_str,
    )
    if m:
        op = m.group(1)
        git_activity[op] = git_activity.get(op, 0) + 1


def _compute_context_spikes(per_turn: list[dict]) -> list[dict]:
    spikes = []
    prev_input = 0
    for t in per_turn:
        delta = t["input_tokens"] - prev_input
        if delta > 20_000:
            spikes.append({
                "turn": t["turn"],
                "timestamp": t["timestamp"],
                "input_delta": delta,
                "input_tokens": t["input_tokens"],
            })
        prev_input = t["input_tokens"]
    return spikes
