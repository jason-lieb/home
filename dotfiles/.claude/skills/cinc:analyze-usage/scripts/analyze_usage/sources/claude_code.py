"""
Claude Code JSONL session loader.
"""
from __future__ import annotations

import json
import re
import shlex
import subprocess
from datetime import datetime
from pathlib import Path

from ..dates import in_date_range
from ..models import CLAUDE_DIR, get_bedrock_rates
from ..utils import _compute_context_spikes, _detect_features, _detect_git, _detect_github_repo, _extract_file_lang


def _load_jsonl(path: Path) -> list[dict]:
    messages = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                messages.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return messages


def summarize_session(messages: list[dict]) -> dict:
    """Extract key stats from a Claude Code session's JSONL messages."""
    input_tokens = output_tokens = cache_creation_tokens = cache_read_tokens = 0
    turns = user_messages = 0
    first_ts = last_ts = None
    cwd = session_id = model = last_prompt = None
    title = ""
    per_turn: list[dict] = []
    compaction_events: list[dict] = []
    large_read_events: list[dict] = []
    tool_usage: dict[str, int] = {}
    languages: dict[str, int] = {}
    features_used: set = set()
    git_activity: dict[str, int] = {}
    git_branch_counts: dict[str, int] = {}

    for msg in messages:
        ts = msg.get("timestamp")
        if ts:
            dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
            if first_ts is None or dt < first_ts:
                first_ts = dt
            if last_ts is None or dt > last_ts:
                last_ts = dt

        if not cwd and msg.get("cwd"):
            cwd = msg["cwd"]
        if not session_id and msg.get("sessionId"):
            session_id = msg["sessionId"]
        if msg.get("gitBranch"):
            branch = msg["gitBranch"]
            git_branch_counts[branch] = git_branch_counts.get(branch, 0) + 1

        if msg.get("type") == "last-prompt":
            last_prompt = msg.get("lastPrompt", "")

        if msg.get("type") == "custom-title":
            title = msg.get("title", "") or msg.get("value", "") or ""

        if msg.get("type") == "agent-name" and not title:
            title = msg.get("agentName", "") or msg.get("value", "") or ""

        if msg.get("type") == "system" and msg.get("subtype") == "local_command":
            content_str = str(msg.get("content", ""))
            m = re.search(r"<command-name>(/(?:auto-)?compact)</command-name>", content_str)
            if m:
                cmd = m.group(1)
                compaction_events.append({
                    "after_turn": turns,
                    "timestamp": ts,
                    "command": cmd,
                    "auto": cmd == "/auto-compact",
                })

        if msg.get("type") == "user":
            content = msg.get("message", {}).get("content", []) if isinstance(msg.get("message"), dict) else []
            if isinstance(content, list):
                if any(isinstance(b, dict) and b.get("type") == "text" for b in content):
                    user_messages += 1
            elif isinstance(content, str) and content.strip():
                user_messages += 1

        if msg.get("type") == "assistant":
            inner = msg.get("message") or {}
            if not model and inner.get("model"):
                model = inner["model"]
            usage = inner.get("usage") or {}
            it = usage.get("input_tokens", 0) or 0
            ot = usage.get("output_tokens", 0) or 0
            cc = usage.get("cache_creation_input_tokens", 0) or 0
            cr = usage.get("cache_read_input_tokens", 0) or 0

            for block in inner.get("content", []) or []:
                if not isinstance(block, dict) or block.get("type") != "tool_use":
                    continue
                tool_name = block.get("name", "unknown")
                tool_usage[tool_name] = tool_usage.get(tool_name, 0) + 1
                _detect_features(tool_name, features_used)
                inp = block.get("input") or {}
                if isinstance(inp, dict):
                    for key in ("file_path", "path", "pattern", "glob"):
                        lang = _extract_file_lang(inp.get(key, ""))
                        if lang:
                            languages[lang] = languages.get(lang, 0) + 1
                if tool_name == "Bash":
                    cmd_str = inp.get("command", "") if isinstance(inp, dict) else ""
                    _detect_git(cmd_str, git_activity)

            if ot > 0:
                turns += 1
                input_tokens += it
                output_tokens += ot
                cache_creation_tokens += cc
                cache_read_tokens += cr
                rates = get_bedrock_rates(model)
                turn_cost = (
                    it * rates["input"]
                    + ot * rates["output"]
                    + cc * rates["cache_write"]
                    + cr * rates["cache_read"]
                ) / 1_000_000
                per_turn.append({
                    "turn": turns,
                    "timestamp": ts,
                    "input_tokens": it,
                    "output_tokens": ot,
                    "cache_creation": cc,
                    "cache_read": cr,
                    "cumulative_input": input_tokens,
                    "est_cost_usd": round(turn_cost, 6) if turn_cost > 0 else None,
                })
                if cc > 5_000:
                    large_read_events.append({"turn": turns, "timestamp": ts, "cache_creation_tokens": cc})

    duration_min = None
    if first_ts and last_ts:
        duration_min = round((last_ts - first_ts).total_seconds() / 60, 1)

    rates = get_bedrock_rates(model)
    est_cost = (
        input_tokens * rates["input"]
        + output_tokens * rates["output"]
        + cache_creation_tokens * rates["cache_write"]
        + cache_read_tokens * rates["cache_read"]
    ) / 1_000_000

    return {
        "session_id": session_id,
        "cwd": cwd,
        "title": title,
        "model": model,
        "date": first_ts.strftime("%Y-%m-%d") if first_ts else None,
        "start_time": first_ts.strftime("%H:%M") if first_ts else None,
        "duration_min": duration_min,
        "turns": turns,
        "user_messages": user_messages,
        "input_tokens": input_tokens,
        "output_tokens": output_tokens,
        "cache_creation_tokens": cache_creation_tokens,
        "cache_read_tokens": cache_read_tokens,
        "reasoning_tokens": 0,
        "total_tokens": input_tokens + output_tokens,
        "cost_usd": None,
        "est_cost_usd": round(est_cost, 4) if est_cost > 0 else None,
        "last_prompt": last_prompt,
        "compaction_events": compaction_events,
        "large_read_events": large_read_events,
        "context_spikes": _compute_context_spikes(per_turn),
        "tool_usage_summary": tool_usage or None,
        "languages": languages or None,
        "features_used": sorted(features_used),
        "git_activity": git_activity or None,
        "git_branch": max(git_branch_counts, key=git_branch_counts.get) if git_branch_counts else None,
        "git_branches": sorted(git_branch_counts) if len(git_branch_counts) > 1 else None,
        "per_turn": per_turn,
        "source": "claude-code",
    }


def find_claude_code_sessions(since: str | None = None, until: str | None = None) -> list[dict]:
    sessions = []
    if not CLAUDE_DIR.exists():
        return sessions

    repo_cache: dict[str, str | None] = {}

    for project_dir in sorted(CLAUDE_DIR.iterdir()):
        if not project_dir.is_dir():
            continue
        for jsonl_file in sorted(project_dir.glob("*.jsonl")):
            messages = _load_jsonl(jsonl_file)
            if not messages:
                continue
            stats = summarize_session(messages)
            if stats["turns"] == 0:
                continue
            if not in_date_range(stats["date"], since, until):
                continue
            stats["project"] = project_dir.name
            stats["file"] = str(jsonl_file)
            if stats.get("session_id"):
                # shlex.quote produces POSIX quoting (bash/zsh); Claude Code runs on macOS/Linux only
                cwd = stats.get("cwd") or ""
                if cwd not in repo_cache:
                    repo_cache[cwd] = _detect_github_repo(cwd or None)
                repo_flag = repo_cache[cwd]
                repo_args = f" --repo {shlex.quote(repo_flag)}" if repo_flag else ""
                stats["transcript_cmd"] = f"uvx claude-code-transcripts json {shlex.quote(str(jsonl_file))} --open{repo_args}"
                file_uri = jsonl_file.as_uri()
                stats["transcript_link"] = f"\033]8;;{file_uri}\033\\[open transcript]\033]8;;\033\\"
            sessions.append(stats)

    return sessions
