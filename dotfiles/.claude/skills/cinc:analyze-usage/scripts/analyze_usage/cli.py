"""
CLI entry point: argument parsing, orchestration, and output dispatch.
"""

import argparse
import json
import sys
from pathlib import Path

from .analysis import is_trivial_session, select_top_sessions
from .dates import resolve_date_range
from .formatters import (
    print_aggregate_summary,
    print_daily_breakdown,
    print_session_detail,
    print_summary_table,
    print_tool_analysis,
    resolve_session,
)
from .loader import find_sessions
from .transcript import open_transcript


def _parse_period(value: str) -> str:
    import re
    if value in ("month", "week"):
        return value
    if re.fullmatch(r"\d+d", value):
        return value
    raise argparse.ArgumentTypeError(
        f"invalid period '{value}': use 'month', 'week', or Nd (e.g. 7d, 14d, 30d)"
    )


def _get_version() -> str:
    try:
        current = Path(__file__).resolve()
        for parent in (current,) + tuple(current.parents):
            plugin_json = parent / ".claude-plugin" / "plugin.json"
            if plugin_json.is_file():
                return json.loads(plugin_json.read_text())["version"]
    except Exception:
        pass
    return "unknown"


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Analyze Claude Code / OpenCode token usage",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 analyze-usage.py                           # top 10 sessions, both sources
  python3 analyze-usage.py --source claude-code      # Claude Code JSONL only
  python3 analyze-usage.py --source opencode         # OpenCode SQLite only
  python3 analyze-usage.py --period 30d --top 20     # rolling last 30 days
  python3 analyze-usage.py --date 2026-03-10         # single date
  python3 analyze-usage.py --since 2026-03-01        # on or after date
  python3 analyze-usage.py --summary                 # aggregate totals only
  python3 analyze-usage.py --daily                   # per-day activity breakdown
  python3 analyze-usage.py --tools                   # tool usage analysis
  python3 analyze-usage.py --session <id>            # detailed per-turn breakdown
  python3 analyze-usage.py --json --top 20           # machine-readable JSON
""",
    )

    p.add_argument("--version", action="version", version=f"%(prog)s {_get_version()}")

    date_group = p.add_mutually_exclusive_group()
    date_group.add_argument("--date", help="Filter sessions by exact date (YYYY-MM-DD)")
    date_group.add_argument(
        "--period",
        metavar="PERIOD",
        type=_parse_period,
        help="Filter by period: 'month' (calendar month), 'week' (Mon–Sun), or Nd for rolling N days (e.g. 7d, 14d, 30d, 90d)",
    )

    p.add_argument("--since", help="Show sessions on or after this date (YYYY-MM-DD)")
    p.add_argument("--until", help="Show sessions on or before this date (YYYY-MM-DD)")
    p.add_argument("--top", type=int, default=10, help="Show top N sessions (default: 10)")
    p.add_argument(
        "--min-per-source",
        type=int,
        default=5,
        dest="min_per_source",
        help="When scanning both sources, guarantee at least this many sessions per source (default: 5)",
    )
    p.add_argument(
        "--sort",
        choices=["input", "cache_read", "output", "turns", "cost", "user_messages", "duration", "tools"],
        default="input",
        help="Sort sessions by: input (default), cache_read, output, turns, cost, user_messages, duration, tools",
    )
    p.add_argument("--summary", action="store_true", help="Show aggregate totals only, without the per-session table")
    p.add_argument("--daily", action="store_true", help="Show per-day activity breakdown")
    p.add_argument("--tools", action="store_true", help="Show tool usage analysis across sessions")
    p.add_argument(
        "--filter",
        action="store_true",
        help="Exclude trivial sessions (< 2 user messages and < 3 turns, or < 1 min duration)",
    )
    p.add_argument("--session", help="Show detailed per-turn breakdown for a session ID")

    output_group = p.add_mutually_exclusive_group()
    output_group.add_argument(
        "--transcript",
        action="store_true",
        help="Open session transcript as HTML (requires --session and claude-code source; uses uvx or uv tool run)",
    )
    output_group.add_argument("--json", action="store_true", help="Output machine-readable JSON instead of formatted text")

    p.add_argument(
        "--source",
        choices=["auto", "claude-code", "opencode"],
        default="auto",
        help="Data source: auto (both), claude-code, or opencode (default: auto)",
    )
    return p.parse_args()


def main() -> None:
    args = parse_args()

    if args.transcript and not args.session:
        print("Error: --transcript requires --session <id>", file=sys.stderr)
        sys.exit(1)

    if (args.date or args.period) and (args.since or args.until):
        print("Error: --since/--until cannot be combined with --date or --period", file=sys.stderr)
        sys.exit(1)

    since, until = resolve_date_range(args)

    if not args.json and not args.transcript:
        print(f"Scanning for sessions (source: {args.source}) ...")

    sessions, missing_sources = find_sessions(since=since, until=until, source=args.source)

    if args.filter:
        original_count = len(sessions)
        sessions = [s for s in sessions if not is_trivial_session(s)]
        filtered_count = original_count - len(sessions)
        if not args.json and filtered_count > 0:
            print(f"  (--filter excluded {filtered_count} trivial session{'s' if filtered_count != 1 else ''})")

    if args.transcript:
        open_transcript(sessions, args.session)
        return

    if args.json:
        if args.session:
            s = resolve_session(sessions, args.session)
            from collections import Counter
            by_source = dict(Counter(x.get("source") for x in sessions))
            envelope = {
                "metadata": {
                    "total_sessions": len(sessions),
                    "sessions_by_source": by_source,
                    "showing": 1,
                    "sort_key": args.sort,
                    "min_per_source": args.min_per_source if args.source == "auto" else 0,
                    "daily_totals": [],
                },
                "sessions": [s],
            }
            print(json.dumps(envelope, indent=2, default=str))
        else:
            summary = [{k: v for k, v in s.items() if k != "per_turn"} for s in sessions]
            min_per_source = args.min_per_source if args.source == "auto" else 0
            result = select_top_sessions(summary, args.top, args.sort, min_per_source)
            from collections import Counter, defaultdict
            by_source = dict(Counter(s.get("source") for s in sessions))
            daily = defaultdict(lambda: {"sessions": 0, "turns": 0, "input_tokens": 0, "output_tokens": 0, "total_tokens": 0, "cost": 0.0})
            for s in sessions:
                day = s.get("date") or "unknown"
                daily[day]["sessions"] += 1
                daily[day]["turns"] += s["turns"]
                daily[day]["input_tokens"] += s["input_tokens"]
                daily[day]["output_tokens"] += s["output_tokens"]
                daily[day]["total_tokens"] += s["total_tokens"]
                daily[day]["cost"] += s.get("cost_usd") or s.get("est_cost_usd") or 0.0
            top_days = sorted(daily.items(), key=lambda x: x[1]["cost"], reverse=True)[:5]
            daily_totals = [{"date": d, **v, "cost": round(v["cost"], 4)} for d, v in top_days]
            envelope = {
                "metadata": {
                    "total_sessions": len(sessions),
                    "sessions_by_source": by_source,
                    "showing": len(result),
                    "sort_key": args.sort,
                    "min_per_source": min_per_source,
                    "daily_totals": daily_totals,
                },
                "sessions": result,
            }
            print(json.dumps(envelope, indent=2, default=str))
        return

    # Build period label for the header
    if since and until and since == until:
        period_label = f" on {since}"
    elif since and until:
        period_label = f" from {since} to {until}"
    elif since:
        period_label = f" since {since}"
    elif until:
        period_label = f" until {until}"
    else:
        period_label = ""

    print(f"Found {len(sessions)} sessions with activity{period_label}.")

    if args.session:
        print_session_detail(sessions, args.session)
    elif args.summary:
        print_aggregate_summary(sessions, since, until, missing_sources=missing_sources)
    elif args.daily:
        print_daily_breakdown(sessions, since, until, missing_sources=missing_sources)
    elif args.tools:
        print_tool_analysis(sessions, missing_sources=missing_sources)
    else:
        min_per_source = args.min_per_source if args.source == "auto" else 0
        print_summary_table(
            sessions,
            top_n=args.top,
            sort_key=args.sort,
            missing_sources=missing_sources,
            min_per_source=min_per_source,
        )
