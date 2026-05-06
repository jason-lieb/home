"""
Session selection, filtering, and analysis helpers.
"""
from __future__ import annotations

from collections import defaultdict

from .models import SORT_KEYS


def _group_by(iterable, key_fn: callable) -> dict:
    result: dict = {}
    for item in iterable:
        result.setdefault(key_fn(item), []).append(item)
    return result


def select_top_sessions(
    sessions: list[dict],
    top_n: int,
    sort_key: str = "input",
    min_per_source: int = 0,
) -> list[dict]:
    """
    Return the top_n sessions by sort_key.
    When min_per_source > 0, guarantees at least that many sessions per source
    even if they don't rank in the top_n (e.g. always show top 5 claude-code
    sessions even when opencode dominates the overall ranking).
    """
    key_fn = SORT_KEYS.get(sort_key, SORT_KEYS["input"])
    sorted_all = sorted(sessions, key=key_fn, reverse=True)
    selected = sorted_all[:top_n]

    if min_per_source > 0:
        selected_ids = {s["session_id"] for s in selected}
        counts_by_source: dict[str, int] = defaultdict(int)
        for s in selected:
            counts_by_source[s.get("source")] += 1

        for src, src_sessions in _group_by(sorted_all, lambda s: s.get("source")).items():
            need = min_per_source - counts_by_source[src]
            if need > 0:
                extras = [s for s in src_sessions if s["session_id"] not in selected_ids][:need]
                selected.extend(extras)
                selected_ids.update(s["session_id"] for s in extras)

        selected = sorted(selected, key=key_fn, reverse=True)

    return selected


def is_trivial_session(s: dict) -> bool:
    """Return True if a session should be excluded by --filter."""
    duration = s.get("duration_min") or 0
    if duration > 0 and duration < 1.0:
        return True
    if (s.get("user_messages") or 0) < 2 and (s.get("turns") or 0) < 3:
        return True
    return False


def aggregate_tools(sessions: list[dict]) -> dict[str, int]:
    merged: dict[str, int] = defaultdict(int)
    for s in sessions:
        for tool, count in (s.get("tool_usage_summary") or {}).items():
            merged[tool] += count
    return dict(merged)


def aggregate_languages(sessions: list[dict]) -> dict[str, int]:
    merged: dict[str, int] = defaultdict(int)
    for s in sessions:
        for lang, count in (s.get("languages") or {}).items():
            merged[lang] += count
    return dict(merged)


def aggregate_features(sessions: list[dict]) -> dict[str, int]:
    counts: dict[str, int] = defaultdict(int)
    for s in sessions:
        for feat in s.get("features_used") or []:
            counts[feat] += 1
    return dict(counts)
