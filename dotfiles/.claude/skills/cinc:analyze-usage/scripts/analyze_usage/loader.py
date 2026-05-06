"""
Session dispatcher: loads from one or both sources and merges results.
"""
from __future__ import annotations

import sys
from pathlib import Path

from .models import CLAUDE_DIR
from .sources.claude_code import find_claude_code_sessions
from .sources.opencode import load_opencode_sessions


def find_sessions(
    since: str | None = None,
    until: str | None = None,
    source: str = "auto",
) -> tuple[list[dict], list[str]]:
    """
    Return (sessions, missing_sources).
    missing_sources lists source names that were expected but not available.
    """
    sessions: list[dict] = []
    missing_sources: list[str] = []

    if source in ("auto", "claude-code"):
        if not CLAUDE_DIR.exists():
            if source == "claude-code":
                print(f"Error: {CLAUDE_DIR} not found. Is Claude Code installed?", file=sys.stderr)
                sys.exit(1)
            else:
                missing_sources.append("claude-code")
        else:
            sessions.extend(find_claude_code_sessions(since=since, until=until))

    if source in ("auto", "opencode"):
        result = load_opencode_sessions(since=since, until=until)
        if result is None:
            if source == "opencode":
                db_path_mac = Path.home() / "Library" / "Application Support" / "opencode" / "opencode.db"
                db_path_linux = Path.home() / ".local" / "share" / "opencode" / "opencode.db"
                print(
                    f"Error: OpenCode database not found.\n"
                    f"Expected locations:\n"
                    f"  macOS:  {db_path_mac}\n"
                    f"  Linux:  {db_path_linux}\n"
                    f"Is OpenCode installed and has it been used?",
                    file=sys.stderr,
                )
                sys.exit(1)
            missing_sources.append("opencode")
        else:
            sessions.extend(result)

    if not sessions and source == "auto":
        if not CLAUDE_DIR.exists() and "opencode" in missing_sources:
            print(
                "Error: No session data found. Neither Claude Code nor OpenCode appears to be installed.",
                file=sys.stderr,
            )
            sys.exit(1)

    return sessions, missing_sources
