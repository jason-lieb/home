"""
Date range resolution and filtering helpers.
"""
from __future__ import annotations

import re
from datetime import date as date_type, timedelta


def resolve_date_range(args) -> tuple[str | None, str | None]:
    """
    Returns (since_str, until_str) from parsed args.
    --date sets an exact day; --period sets a calendar range; --since/--until set explicit bounds.
    Returned strings are YYYY-MM-DD or None.
    """
    today = date_type.today()

    if args.date:
        return args.date, args.date

    if args.period == "month":
        since = today.replace(day=1).isoformat()
        if today.month == 12:
            until = today.replace(year=today.year + 1, month=1, day=1) - timedelta(days=1)
        else:
            until = today.replace(month=today.month + 1, day=1) - timedelta(days=1)
        return since, until.isoformat()

    if args.period == "week":
        monday = today - timedelta(days=today.weekday())
        sunday = monday + timedelta(days=6)
        return monday.isoformat(), sunday.isoformat()

    if args.period and re.fullmatch(r"(\d+)d", args.period):
        n = int(re.fullmatch(r"(\d+)d", args.period).group(1))
        since = (today - timedelta(days=n - 1)).isoformat()
        return since, today.isoformat()

    return args.since, args.until


def in_date_range(date_str: str | None, since: str | None, until: str | None) -> bool:
    """Return True if date_str (YYYY-MM-DD) falls within [since, until] (either may be None)."""
    if date_str is None:
        return True
    if since and date_str < since:
        return False
    if until and date_str > until:
        return False
    return True
