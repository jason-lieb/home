"""
OpenCode SQLite session loader.
"""
from __future__ import annotations

import json
import os
import sqlite3
import sys
from datetime import datetime, timezone
from pathlib import Path

from ..dates import in_date_range
from ..models import get_bedrock_rates
from ..utils import _compute_context_spikes, _detect_features, _detect_git, _extract_file_lang


def find_opencode_db() -> Path | None:
    """Return the path to the OpenCode SQLite database, or None if not found."""
    candidates = []
    xdg = os.environ.get("XDG_DATA_HOME")
    if xdg:
        candidates.append(Path(xdg) / "opencode" / "opencode.db")
    if sys.platform == "darwin":
        candidates.append(Path.home() / "Library" / "Application Support" / "opencode" / "opencode.db")
    candidates.append(Path.home() / ".local" / "share" / "opencode" / "opencode.db")
    return next((p for p in candidates if p.exists()), None)


def _parse_ts(ts_value) -> datetime | None:
    if ts_value is None:
        return None
    if isinstance(ts_value, (int, float)):
        try:
            return datetime.fromtimestamp(ts_value / 1000, tz=timezone.utc)
        except Exception:
            return None
    if isinstance(ts_value, str):
        try:
            dt = datetime.fromisoformat(ts_value.replace("Z", "+00:00"))
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            return dt
        except Exception:
            return None
    return None


def _chunked_in_query(con: sqlite3.Connection, sql_template: str, ids: list) -> list:
    """Execute a query with a large IN clause by chunking ids into batches of 500."""
    results = []
    for i in range(0, len(ids), 500):
        chunk = ids[i:i + 500]
        placeholders = ",".join("?" * len(chunk))
        try:
            rows = con.execute(sql_template.format(placeholders=placeholders), chunk).fetchall()
            results.extend(rows)
        except sqlite3.OperationalError as e:
            print(f"Warning: OpenCode batch query failed for chunk {i // 500 + 1}: {e}", file=sys.stderr)
    return results


def _compute_est_cost(
    model: str | None,
    cost_usd: float,
    input_tokens: int,
    output_tokens: int,
    cache_creation_tokens: int,
    cache_read_tokens: int,
) -> float | None:
    """Estimate cost from Bedrock rates when cost_usd is not available and the model is Bedrock-hosted."""
    if cost_usd:
        return None
    if not model or "amazon-bedrock" not in model.lower():
        return None
    rates = get_bedrock_rates(model)
    est = (
        input_tokens * rates["input"]
        + output_tokens * rates["output"]
        + cache_creation_tokens * rates["cache_write"]
        + cache_read_tokens * rates["cache_read"]
    ) / 1_000_000
    return round(est, 4) if est > 0 else None


def summarize_opencode_session(session_row: dict, messages: list[dict], parts_by_message: dict) -> dict:
    """
    Build a summary dict from an OpenCode session row + its messages + parts.

    Supports both the legacy schema (session row has a JSON 'data' column) and the
    current schema (session row has direct columns: id, title, directory, time_created, …).
    """
    if "data" in session_row and session_row.get("data"):
        try:
            session_data = json.loads(session_row["data"]) if isinstance(session_row["data"], str) else (session_row["data"] or {})
        except Exception:
            session_data = {}
        session_id = session_row.get("id") or session_data.get("id")
        cwd = session_data.get("directory") or session_data.get("cwd")
        title = session_data.get("title") or session_data.get("slug") or ""
        session_ts = session_data.get("time_created") or session_row.get("time_created")
    else:
        session_data = {}
        session_id = session_row.get("id")
        cwd = session_row.get("directory") or session_row.get("cwd")
        title = session_row.get("title") or session_row.get("slug") or ""
        session_ts = session_row.get("time_created")

    input_tokens = output_tokens = cache_creation_tokens = cache_read_tokens = reasoning_tokens = 0
    cost_usd = 0.0
    turns = user_messages = 0
    first_ts = _parse_ts(session_ts)
    last_ts = first_ts
    model = last_prompt = None
    per_turn: list[dict] = []
    compaction_events: list[dict] = []
    large_read_events: list[dict] = []
    tool_usage: dict[str, int] = {}
    languages: dict[str, int] = {}
    features_used: set = set()
    git_activity: dict[str, int] = {}

    for msg_row in messages:
        try:
            msg = json.loads(msg_row["data"]) if isinstance(msg_row["data"], str) else (msg_row["data"] or {})
        except Exception:
            msg = {}

        msg_id = msg_row.get("id") or msg.get("id")
        role = msg.get("role") or msg.get("type")

        time_field = msg.get("time")
        if isinstance(time_field, dict):
            ts_raw = time_field.get("created") or time_field.get("completed")
        else:
            ts_raw = time_field or msg.get("created_at") or msg_row.get("time_created")
        ts_dt = _parse_ts(ts_raw)
        ts_str = ts_dt.isoformat() if ts_dt else None

        if ts_dt:
            if first_ts is None or ts_dt < first_ts:
                first_ts = ts_dt
            if last_ts is None or ts_dt > last_ts:
                last_ts = ts_dt

        if not model:
            model_id = msg.get("modelID")
            provider_id = msg.get("providerID") or msg.get("provider")
            model_field = msg.get("model")
            if isinstance(model_field, dict):
                model_id = model_id or model_field.get("modelID")
                provider_id = provider_id or model_field.get("providerID")
            else:
                model_id = model_id or model_field
            if model_id:
                model = f"{provider_id}/{model_id}" if provider_id else model_id

        if role in ("user", "human"):
            content = msg.get("content") or ""
            if isinstance(content, list):
                texts = [b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text"]
                if texts:
                    user_messages += 1
                content = " ".join(texts)
            elif isinstance(content, str) and content.strip():
                user_messages += 1

            # Fallback: OpenCode stores user text in parts, not in message content
            if not content or not content.strip():
                part_texts = []
                for p_row in (parts_by_message.get(msg_id) or []):
                    try:
                        p = json.loads(p_row["data"]) if isinstance(p_row["data"], str) else (p_row["data"] or {})
                    except Exception:
                        continue
                    if p.get("type") == "text" and p.get("text", "").strip():
                        part_texts.append(p["text"].strip())
                if part_texts:
                    user_messages += 1
                    content = " ".join(part_texts)

            if content and content.strip():
                last_prompt = content

        if role in ("assistant", "ai"):
            tokens = msg.get("tokens") or {}
            cache = tokens.get("cache") or {}
            it = tokens.get("input", 0) or 0
            ot = tokens.get("output", 0) or 0
            rt = tokens.get("reasoning", 0) or 0
            cc = cache.get("write", 0) or 0
            cr = cache.get("read", 0) or 0
            msg_cost = msg.get("cost") or 0.0

            if ot > 0:
                turns += 1
                input_tokens += it
                output_tokens += ot
                cache_creation_tokens += cc
                cache_read_tokens += cr
                reasoning_tokens += rt
                cost_usd += msg_cost
                per_turn.append({
                    "turn": turns,
                    "timestamp": ts_str,
                    "input_tokens": it,
                    "output_tokens": ot,
                    "cache_creation": cc,
                    "cache_read": cr,
                    "reasoning_tokens": rt,
                    "cost_usd": msg_cost,
                    "cumulative_input": input_tokens,
                })
                if cc > 5_000:
                    large_read_events.append({"turn": turns, "timestamp": ts_str, "cache_creation_tokens": cc})

        for part_row in (parts_by_message.get(msg_id) or []):
            try:
                part = json.loads(part_row["data"]) if isinstance(part_row["data"], str) else (part_row["data"] or {})
            except Exception:
                part = {}

            part_type = part.get("type") or part.get("kind")

            if part_type == "compaction":
                auto_flag = part.get("auto", False)
                compaction_events.append({
                    "after_turn": turns,
                    "timestamp": ts_str,
                    "command": "/auto-compact" if auto_flag else "/compact",
                    "auto": auto_flag,
                    "overflow": part.get("overflow", False),
                })

            elif part_type == "tool":
                tool_name = part.get("tool") or part.get("toolName") or part.get("name") or "unknown"
                tool_usage[tool_name] = tool_usage.get(tool_name, 0) + 1
                _detect_features(tool_name, features_used)
                state = part.get("state") or {}
                inp = (state.get("input") if isinstance(state, dict) else None) or part.get("input") or {}
                if isinstance(inp, dict):
                    for key in ("file_path", "path", "pattern", "glob"):
                        lang = _extract_file_lang(inp.get(key, ""))
                        if lang:
                            languages[lang] = languages.get(lang, 0) + 1
                if tool_name == "bash":
                    cmd_str = inp.get("command", "") if isinstance(inp, dict) else ""
                    _detect_git(cmd_str, git_activity)

    duration_min = None
    if first_ts and last_ts:
        duration_min = round((last_ts - first_ts).total_seconds() / 60, 1)

    date_str = first_ts.strftime("%Y-%m-%d") if first_ts else None
    start_time_str = first_ts.strftime("%H:%M") if first_ts else None

    return {
        "session_id": session_id,
        "cwd": cwd,
        "title": title,
        "model": model,
        "date": date_str,
        "start_time": start_time_str,
        "duration_min": duration_min,
        "turns": turns,
        "user_messages": user_messages,
        "input_tokens": input_tokens,
        "output_tokens": output_tokens,
        "cache_creation_tokens": cache_creation_tokens,
        "cache_read_tokens": cache_read_tokens,
        "reasoning_tokens": reasoning_tokens,
        "total_tokens": input_tokens + output_tokens,
        "cost_usd": round(cost_usd, 6) if cost_usd else None,
        "est_cost_usd": _compute_est_cost(model, cost_usd, input_tokens, output_tokens, cache_creation_tokens, cache_read_tokens),
        "last_prompt": last_prompt,
        "compaction_events": compaction_events,
        "large_read_events": large_read_events,
        "context_spikes": _compute_context_spikes(per_turn),
        "tool_usage_summary": tool_usage or None,
        "languages": languages or None,
        "features_used": sorted(features_used),
        "git_activity": git_activity or None,
        "per_turn": per_turn,
        "source": "opencode",
        "project": cwd or title or str(session_id or "")[:12],
    }


def load_opencode_sessions(since: str | None = None, until: str | None = None) -> list[dict] | None:
    """Return sessions list, or None if the DB was not found."""
    db_path = find_opencode_db()
    if db_path is None:
        return None

    try:
        con = sqlite3.connect(str(db_path))
        con.row_factory = sqlite3.Row
    except Exception as e:
        print(f"Warning: could not open OpenCode DB at {db_path}: {e}", file=sys.stderr)
        return []

    sessions = []
    try:
        session_rows = con.execute("SELECT * FROM session").fetchall()
        session_ids = [r["id"] for r in session_rows]

        all_msg_rows = _chunked_in_query(
            con,
            "SELECT id, session_id, time_created, data FROM message WHERE session_id IN ({placeholders})",
            session_ids,
        ) if session_ids else []

        msgs_by_session: dict = {}
        all_msg_ids = []
        for m in all_msg_rows:
            m_dict = dict(m)
            msgs_by_session.setdefault(m_dict.get("session_id"), []).append(m_dict)
            if m_dict.get("id"):
                all_msg_ids.append(m_dict["id"])
        del all_msg_rows

        parts_by_message: dict = {}
        if all_msg_ids:
            for p in _chunked_in_query(
                con,
                "SELECT id, message_id, data FROM part WHERE message_id IN ({placeholders})",
                all_msg_ids,
            ):
                p_dict = dict(p)
                parts_by_message.setdefault(p_dict.get("message_id"), []).append(p_dict)

        for s_row in session_rows:
            s_dict = dict(s_row)
            msg_list = msgs_by_session.get(s_dict["id"], [])
            summary = summarize_opencode_session(s_dict, msg_list, parts_by_message)
            if summary["turns"] == 0:
                continue
            if not in_date_range(summary["date"], since, until):
                continue
            sessions.append(summary)

    except Exception as e:
        print(f"Warning: error reading OpenCode DB: {e}", file=sys.stderr)
    finally:
        con.close()

    return sessions
