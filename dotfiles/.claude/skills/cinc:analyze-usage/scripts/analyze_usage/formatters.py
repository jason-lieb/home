"""
Human-readable output formatters (tables, summaries, detail views).
"""
from __future__ import annotations

import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path

from .analysis import aggregate_features, aggregate_languages, aggregate_tools, select_top_sessions


# ---------------------------------------------------------------------------
# Token / cost formatting helpers
# ---------------------------------------------------------------------------

def fmt_tokens(n: int) -> str:
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n / 1_000:.0f}k"
    return str(n)


def fmt_cost(c, estimated: bool = False) -> str:
    if c is None:
        return "-"
    prefix = "~" if estimated else ""
    if c >= 1.0:
        return f"{prefix}${c:.2f}"
    if c >= 0.01:
        return f"{prefix}${c:.3f}"
    return f"{prefix}${c:.4f}"


def _effective_cost(s: dict) -> tuple[float | None, bool]:
    """Return (cost_value, is_estimated). Prefers cost_usd, falls back to est_cost_usd."""
    if s.get("cost_usd") is not None:
        return s["cost_usd"], False
    if s.get("est_cost_usd") is not None:
        return s["est_cost_usd"], True
    return None, False


# ---------------------------------------------------------------------------
# Summary table
# ---------------------------------------------------------------------------

def print_summary_table(
    sessions: list[dict],
    top_n: int,
    sort_key: str = "input",
    missing_sources: list[str] | None = None,
    min_per_source: int = 0,
) -> None:
    if not sessions:
        print("No sessions found.")
        return

    selected = select_top_sessions(sessions, top_n, sort_key, min_per_source)
    has_cost = any(_effective_cost(s)[0] is not None for s in selected)
    width = 168 if has_cost else 158

    header = (
        f"{'SESSION_ID':<38} {'DATE':<12} {'START':<7} {'DUR(m)':<8} {'TURNS':<7} "
        f"{'INPUT':>9} {'OUTPUT':>9} {'CACHE_CR':>10} {'CACHE_RD':>10} "
        f"{'COMPACT':<9} "
    )
    if has_cost:
        header += f"{'COST':>8} "
    header += f"{'SRC':<12} {'MODEL':<25} {'PROJECT/CWD'}"

    print(f"\n{'=' * width}")
    print(header)
    print(f"{'-' * width}")

    for s in selected:
        cwd_short = (s["cwd"] or "")[-30:] if s["cwd"] else (s.get("project") or "")[-30:]
        session_id_short = str(s.get("session_id") or "")[:36]
        line = (
            f"{session_id_short:<38} "
            f"{s['date'] or '?':<12} "
            f"{s['start_time'] or '?':<7} "
            f"{str(s['duration_min'] or '?'):<8} "
            f"{s['turns']:<7} "
            f"{fmt_tokens(s['input_tokens']):>9} "
            f"{fmt_tokens(s['output_tokens']):>9} "
            f"{fmt_tokens(s['cache_creation_tokens']):>10} "
            f"{fmt_tokens(s['cache_read_tokens']):>10} "
            f"{'yes' if s['compaction_events'] else '-':<9} "
        )
        if has_cost:
            cost_val, cost_est = _effective_cost(s)
            line += f"{fmt_cost(cost_val, estimated=cost_est):>8} "
        line += f"{s.get('source', '?')[:10]:<12} {(s['model'] or 'unknown'):<25} {cwd_short}"
        print(line)

    print(f"{'=' * width}")
    total_input = sum(s["input_tokens"] for s in selected)
    total_output = sum(s["output_tokens"] for s in selected)
    total_cache_cr = sum(s["cache_creation_tokens"] for s in selected)
    total_cr = sum(s["cache_read_tokens"] for s in selected)
    total_cost = sum(_effective_cost(s)[0] or 0 for s in selected)
    totals = (
        f"{'TOTAL':<38} {'':>12} {'':>7} {'':>8} {'':>7} "
        f"{fmt_tokens(total_input):>9} {fmt_tokens(total_output):>9} "
        f"{fmt_tokens(total_cache_cr):>10} {fmt_tokens(total_cr):>10} {'':>9} "
    )
    if has_cost:
        totals += f"{fmt_cost(total_cost):>8} "
    print(totals)

    floor_note = f" (includes up to {min_per_source} per source)" if min_per_source > 0 and len(selected) > top_n else ""
    print(f"\nShowing top {len(selected)} of {len(sessions)} sessions, sorted by {sort_key}{floor_note}.")
    print(f"To inspect a session in detail: python3 {sys.argv[0]} --session <SESSION_ID>")
    print(f"\nNote: CACHE_CR = new tokens written to prompt cache (billed at ~25% rate on Bedrock)")
    print(f"      CACHE_RD = tokens served from cache (billed at ~10% rate on Bedrock)")
    print(f"      COMPACT  = session had a /compact or /auto-compact event")
    print(f"      SRC      = data source (claude-code or opencode)")
    if has_cost:
        print(f"      COST     = dollar cost (~prefix = estimated from Bedrock rates; exact for OpenCode)")

    if missing_sources:
        for src in missing_sources:
            print(f"\nNote: {src} data not available (not installed or no data found).")


# ---------------------------------------------------------------------------
# Aggregate summary
# ---------------------------------------------------------------------------

def print_aggregate_summary(
    sessions: list[dict],
    since: str | None,
    until: str | None,
    missing_sources: list[str] | None = None,
) -> None:
    if not sessions:
        print("No sessions found.")
        return

    total_sessions = len(sessions)
    total_turns = sum(s["turns"] for s in sessions)
    total_input = sum(s["input_tokens"] for s in sessions)
    total_output = sum(s["output_tokens"] for s in sessions)
    total_cache_cr = sum(s["cache_creation_tokens"] for s in sessions)
    total_cache_rd = sum(s["cache_read_tokens"] for s in sessions)
    total_cost = sum(_effective_cost(s)[0] or 0 for s in sessions)
    total_compactions = sum(len(s["compaction_events"]) for s in sessions)
    total_large_reads = sum(len(s["large_read_events"]) for s in sessions)
    total_context_spikes = sum(len(s["context_spikes"]) for s in sessions)
    has_cost = any(_effective_cost(s)[0] is not None for s in sessions)

    dates = sorted(s["date"] for s in sessions if s.get("date"))
    date_range = f"{dates[0]} – {dates[-1]}" if dates else "unknown"

    if since and until and since == until:
        period_label = since
    elif since and until:
        period_label = f"{since} – {until}"
    elif since:
        period_label = f"since {since}"
    elif until:
        period_label = f"until {until}"
    else:
        period_label = "all time"

    print(f"\n{'=' * 60}")
    print(f"  USAGE SUMMARY  ({period_label})")
    print(f"{'=' * 60}")
    print(f"  Sessions:          {total_sessions:>10,}")
    print(f"  Turns:             {total_turns:>10,}")
    print(f"  Input tokens:      {total_input:>10,}  ({fmt_tokens(total_input)})")
    print(f"  Output tokens:     {total_output:>10,}  ({fmt_tokens(total_output)})")
    print(f"  Cache creation:    {total_cache_cr:>10,}  ({fmt_tokens(total_cache_cr)})")
    print(f"  Cache reads:       {total_cache_rd:>10,}  ({fmt_tokens(total_cache_rd)})")
    if has_cost:
        print(f"  Total cost:        {fmt_cost(total_cost):>10}")
    print(f"  Compaction events: {total_compactions:>10,}")
    print(f"  Large read events: {total_large_reads:>10,}")
    print(f"  Context spikes:    {total_context_spikes:>10,}")
    print(f"  Data range:        {date_range}")
    print(f"{'=' * 60}")

    # By-project breakdown
    by_project: dict = defaultdict(lambda: {"sessions": 0, "turns": 0, "input": 0,
                                             "output": 0, "cache_cr": 0, "cache_rd": 0, "cost": 0.0})
    for s in sessions:
        proj = (s["cwd"] or "").split("/")[-1] or s.get("project") or "unknown"
        by_project[proj]["sessions"] += 1
        by_project[proj]["turns"] += s["turns"]
        by_project[proj]["input"] += s["input_tokens"]
        by_project[proj]["output"] += s["output_tokens"]
        by_project[proj]["cache_cr"] += s["cache_creation_tokens"]
        by_project[proj]["cache_rd"] += s["cache_read_tokens"]
        by_project[proj]["cost"] += _effective_cost(s)[0] or 0.0

    sorted_projects = sorted(by_project.items(), key=lambda x: x[1]["cache_rd"], reverse=True)
    print(f"\n  {'PROJECT':<35} {'SESS':>5} {'TURNS':>6} {'INPUT':>8} {'CACHE_RD':>10}", end="")
    if has_cost:
        print(f"  {'COST':>8}", end="")
    print()
    print(f"  {'-' * 35} {'-' * 5} {'-' * 6} {'-' * 8} {'-' * 10}", end="")
    if has_cost:
        print(f"  {'-' * 8}", end="")
    print()
    for proj, stats in sorted_projects:
        line = f"  {proj[:35]:<35} {stats['sessions']:>5} {stats['turns']:>6} {fmt_tokens(stats['input']):>8} {fmt_tokens(stats['cache_rd']):>10}"
        if has_cost:
            line += f"  {fmt_cost(stats['cost']):>8}"
        print(line)

    active_days = len(set(s["date"] for s in sessions if s.get("date")))
    print(f"  Active days:       {active_days:>10,}")
    print()

    merged_tools = aggregate_tools(sessions)
    if merged_tools:
        total_calls = sum(merged_tools.values())
        sorted_tools = sorted(merged_tools.items(), key=lambda x: x[1], reverse=True)
        print(f"  TOP TOOLS  ({total_calls:,} total calls)")
        print(f"  {'-' * 40}")
        for tool, cnt in sorted_tools[:15]:
            pct = cnt / total_calls * 100
            print(f"  {tool[:30]:<30}  {cnt:>6,}  ({pct:.0f}%)")
        print()

    merged_langs = aggregate_languages(sessions)
    if merged_langs:
        total_lang_refs = sum(merged_langs.values())
        print(f"  LANGUAGES DETECTED")
        print(f"  {'-' * 40}")
        for lang, cnt in sorted(merged_langs.items(), key=lambda x: x[1], reverse=True)[:10]:
            pct = cnt / total_lang_refs * 100
            print(f"  {lang:<20}  {cnt:>6,} refs  ({pct:.0f}%)")
        print()

    if missing_sources:
        for src in missing_sources:
            print(f"Note: {src} data not available (not installed or no data found).")


# ---------------------------------------------------------------------------
# Daily breakdown
# ---------------------------------------------------------------------------

def print_daily_breakdown(
    sessions: list[dict],
    since: str | None,
    until: str | None,
    missing_sources: list[str] | None = None,
) -> None:
    if not sessions:
        print("No sessions found.")
        return

    by_day: dict = defaultdict(lambda: {"sessions": 0, "turns": 0, "user_messages": 0, "input": 0, "output": 0, "cost": 0.0})
    has_cost = any(_effective_cost(s)[0] is not None for s in sessions)

    for s in sessions:
        day = s.get("date") or "unknown"
        by_day[day]["sessions"] += 1
        by_day[day]["turns"] += s["turns"]
        by_day[day]["user_messages"] += s.get("user_messages") or 0
        by_day[day]["input"] += s["input_tokens"]
        by_day[day]["output"] += s["output_tokens"]
        by_day[day]["cost"] += _effective_cost(s)[0] or 0.0

    sorted_days = sorted(by_day.items())

    print(f"\n{'=' * 80}")
    print(f"  DAILY ACTIVITY BREAKDOWN")
    print(f"{'=' * 80}")

    header = f"  {'DATE':<12} {'SESS':>5} {'TURNS':>6} {'USER_MSGS':>9} {'INPUT':>9} {'OUTPUT':>8}"
    if has_cost:
        header += f" {'COST':>8}"
    print(header)
    print(f"  {'-' * 12} {'-' * 5} {'-' * 6} {'-' * 9} {'-' * 9} {'-' * 8}", end="")
    if has_cost:
        print(f" {'-' * 8}", end="")
    print()

    for day, stats in sorted_days:
        line = (
            f"  {day:<12} {stats['sessions']:>5} {stats['turns']:>6} "
            f"{stats['user_messages']:>9} {fmt_tokens(stats['input']):>9} "
            f"{fmt_tokens(stats['output']):>8}"
        )
        if has_cost:
            line += f" {fmt_cost(stats['cost']):>8}"
        print(line)

    print(f"{'=' * 80}")
    print(f"  {len(sorted_days)} active days across {len(sessions)} sessions")

    if missing_sources:
        for src in missing_sources:
            print(f"\nNote: {src} data not available (not installed or no data found).")


# ---------------------------------------------------------------------------
# Tool analysis
# ---------------------------------------------------------------------------

def print_tool_analysis(sessions: list[dict], missing_sources: list[str] | None = None) -> None:
    if not sessions:
        print("No sessions found.")
        return

    sessions_with_tools = [s for s in sessions if s.get("tool_usage_summary")]
    if not sessions_with_tools:
        print("No tool usage data found. Tool data is available for Claude Code sessions (v1.2+) and OpenCode sessions.")
        return

    merged_tools = aggregate_tools(sessions_with_tools)
    total_calls = sum(merged_tools.values())
    sorted_tools = sorted(merged_tools.items(), key=lambda x: x[1], reverse=True)

    print(f"\n{'=' * 60}")
    print(f"  TOOL USAGE ANALYSIS  ({len(sessions_with_tools)} sessions with tool data)")
    print(f"{'=' * 60}")
    print(f"  Total tool calls: {total_calls:,}")
    print()
    print(f"  {'TOOL':<35} {'CALLS':>7} {'PCT':>6}")
    print(f"  {'-' * 35} {'-' * 7} {'-' * 6}")
    for tool, count in sorted_tools[:15]:
        pct = count / total_calls * 100 if total_calls else 0
        print(f"  {tool[:35]:<35} {count:>7,} {pct:>5.1f}%")
    if len(sorted_tools) > 15:
        rest = sum(c for _, c in sorted_tools[15:])
        print(f"  {'(other)':<35} {rest:>7,} {rest / total_calls * 100:>5.1f}%")

    feature_counts = aggregate_features(sessions)
    if feature_counts:
        print(f"\n  Features used across sessions:")
        for feat, cnt in sorted(feature_counts.items(), key=lambda x: x[1], reverse=True):
            print(f"    {feat}: {cnt} session{'s' if cnt != 1 else ''}")

    flagged = []
    for s in sessions_with_tools:
        tool_calls = sum((s.get("tool_usage_summary") or {}).values())
        turns = s.get("turns") or 1
        ratio = tool_calls / turns
        if ratio > 5 and tool_calls > 20:
            flagged.append((s, ratio, tool_calls))

    if flagged:
        print(f"\n  Sessions with high tool-to-turn ratio (possible agent loops):")
        for s, ratio, tool_calls in sorted(flagged, key=lambda x: x[1], reverse=True)[:5]:
            sid = str(s.get("session_id") or "")[:20]
            print(f"    {sid}  {tool_calls} calls / {s['turns']} turns = {ratio:.1f}x  ({s.get('date')})")

    merged_langs = aggregate_languages(sessions)
    if merged_langs:
        total_lang_refs = sum(merged_langs.values())
        print(f"\n  Languages detected from file paths:")
        for lang, cnt in sorted(merged_langs.items(), key=lambda x: x[1], reverse=True)[:10]:
            pct = cnt / total_lang_refs * 100
            print(f"    {lang:<20} {cnt:>5,} refs  ({pct:.0f}%)")

    print()
    if missing_sources:
        for src in missing_sources:
            print(f"Note: {src} data not available (not installed or no data found).")


# ---------------------------------------------------------------------------
# Session detail
# ---------------------------------------------------------------------------

def resolve_session(sessions: list[dict], session_id: str) -> dict:
    """Resolve a session_id prefix/substring to a unique session, or exit with an error."""
    exact = [s for s in sessions if str(s.get("session_id") or "") == session_id]
    if len(exact) == 1:
        return exact[0]
    if len(exact) > 1:
        primary = [s for s in exact if s.get("file") and session_id in Path(s["file"]).stem]
        if len(primary) == 1:
            return primary[0]
        return max(exact, key=lambda s: s.get("turns") or 0)

    sub = [s for s in sessions if s.get("session_id") and session_id in str(s["session_id"])]
    if len(sub) == 1:
        return sub[0]
    if len(sub) > 1:
        primary = [s for s in sub if s.get("file") and session_id in Path(s["file"]).stem]
        if len(primary) == 1:
            return primary[0]
        ids = "\n  ".join(
            f"{s['session_id']}  ({Path(s['file']).name if s.get('file') else 'opencode'})"
            for s in sub
        )
        print(f"Error: '{session_id}' is ambiguous — matches {len(sub)} sessions:\n  {ids}", file=sys.stderr)
        sys.exit(1)

    print(f"Error: session '{session_id}' not found. Run without --session to list sessions.", file=sys.stderr)
    sys.exit(1)


def print_session_detail(sessions: list[dict], session_id: str) -> None:
    s = resolve_session(sessions, session_id)
    print(f"\n{'=' * 80}")
    print(f"Session:     {s['session_id']}")
    print(f"Source:      {s.get('source', 'unknown')}")
    if s.get("title"):
        print(f"Title:       {s['title']}")
    print(f"Date:        {s['date']} {s['start_time']}")
    print(f"Duration:    {s['duration_min']} minutes")
    print(f"Project:     {s['cwd']}")
    print(f"Model:       {s['model']}")
    print(f"Turns:       {s['turns']}")
    if s.get("user_messages") is not None:
        print(f"User msgs:   {s['user_messages']}")
    cost_val, cost_est = _effective_cost(s)
    if cost_val is not None:
        label = "Est. cost" if cost_est else "Cost"
        print(f"{label}:     {fmt_cost(cost_val, estimated=cost_est)}")
    if s.get("reasoning_tokens"):
        print(f"Reasoning:   {fmt_tokens(s['reasoning_tokens'])} tokens")
    if s.get("features_used"):
        print(f"Features:    {', '.join(s['features_used'])}")
    if s.get("git_activity"):
        git_str = ", ".join(f"{op}:{cnt}" for op, cnt in sorted(s["git_activity"].items()))
        print(f"Git:         {git_str}")
    if s.get("languages"):
        lang_str = ", ".join(
            f"{lang}({cnt})" for lang, cnt in
            sorted(s["languages"].items(), key=lambda x: x[1], reverse=True)[:5]
        )
        print(f"Languages:   {lang_str}")
    if s["last_prompt"]:
        lp = s["last_prompt"][:120] + ("..." if len(s["last_prompt"]) > 120 else "")
        print(f"Last prompt: {lp}")
    print(f"{'=' * 80}")

    if s["compaction_events"]:
        print(f"\nCompaction events ({len(s['compaction_events'])}):")
        for e in s["compaction_events"]:
            auto_note = " (AUTO - context was full)" if e.get("auto") else ""
            print(f"  {e['command']} after turn {e['after_turn']} at {e['timestamp']}{auto_note}")

    if s["large_read_events"]:
        print(f"\nLarge file reads into context (cache_creation > 5k tokens):")
        for e in s["large_read_events"]:
            print(f"  Turn {e['turn']}: +{fmt_tokens(e['cache_creation_tokens'])} cache tokens")

    if s["context_spikes"]:
        print(f"\nContext spikes (input grew >20k in one turn - large tool result injected):")
        for e in s["context_spikes"]:
            print(f"  Turn {e['turn']}: +{fmt_tokens(e['input_delta'])} tokens (total input now {fmt_tokens(e['input_tokens'])})")

    if s.get("tool_usage_summary"):
        print(f"\nTool usage breakdown:")
        for tool_name, count in sorted(s["tool_usage_summary"].items(), key=lambda x: x[1], reverse=True):
            print(f"  {tool_name}: {count}")

    print(f"\nPer-turn token breakdown:\n")
    has_reasoning = any(t.get("reasoning_tokens") for t in s["per_turn"])
    has_cost_col = any(t.get("cost_usd") is not None or t.get("est_cost_usd") is not None for t in s["per_turn"])
    turn_cost_estimated = not any(t.get("cost_usd") for t in s["per_turn"])

    col_header = f"{'TURN':<6} {'TIME':<9} {'INPUT':>9} {'OUTPUT':>9} {'CACHE_CR':>10} {'CACHE_RD':>10}"
    if has_reasoning:
        col_header += f" {'REASON':>8}"
    if has_cost_col:
        col_header += f" {'~COST' if turn_cost_estimated else 'COST':>8}"
    col_header += f" {'CUMUL_IN':>10}  NOTE"
    print(col_header)
    print(f"{'-' * 80}")

    compact_after = {e["after_turn"] for e in s["compaction_events"]}
    for t in s["per_turn"]:
        ts_str = ""
        if t["timestamp"]:
            try:
                dt = datetime.fromisoformat(str(t["timestamp"]).replace("Z", "+00:00"))
                ts_str = dt.strftime("%H:%M:%S")
            except Exception:
                pass
        note = ""
        if t["cache_creation"] > 5000:
            note = f"<-- large read ({fmt_tokens(t['cache_creation'])} cached)"
        if t["turn"] in compact_after:
            note = "<-- compaction"
        row = (
            f"{t['turn']:<6} {ts_str:<9} "
            f"{fmt_tokens(t['input_tokens']):>9} {fmt_tokens(t['output_tokens']):>9} "
            f"{fmt_tokens(t['cache_creation']):>10} {fmt_tokens(t['cache_read']):>10}"
        )
        if has_reasoning:
            row += f" {fmt_tokens(t.get('reasoning_tokens') or 0):>8}"
        if has_cost_col:
            turn_cost_val = t.get("cost_usd") or t.get("est_cost_usd")
            row += f" {fmt_cost(turn_cost_val, estimated=turn_cost_estimated):>8}"
        row += f" {fmt_tokens(t['cumulative_input']):>10}  {note}"
        print(row)

    print(f"\nNote: CACHE_CR = tokens written to prompt cache (billed at ~25% of input rate on Bedrock)")
    print(f"      CACHE_RD = tokens read from cache (billed at ~10% of input rate on Bedrock)")
    print(f"      Rapidly growing CUMUL_IN = context window compounding across turns")
