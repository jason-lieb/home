"""
HTML transcript viewer (opens a claude-code session in the browser via uvx or uv tool run).
"""
from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from .formatters import resolve_session
from .utils import _detect_github_repo


def open_transcript(sessions: list[dict], session_id: str) -> None:
    s = resolve_session(sessions, session_id)

    if s.get("source") != "claude-code":
        print(
            f"Error: --transcript only works with claude-code sessions "
            f"(this session is source={s.get('source')!r}).",
            file=sys.stderr,
        )
        sys.exit(1)

    jsonl_file = s.get("file")
    if not jsonl_file or not Path(jsonl_file).exists():
        print(f"Error: JSONL file not found for session {s['session_id']}.", file=sys.stderr)
        sys.exit(1)

    if shutil.which("uvx"):
        runner = ["uvx"]
    elif shutil.which("uv"):
        runner = ["uv", "tool", "run"]
    else:
        print(
            "Error: neither 'uvx' nor 'uv' found. Install uv to use --transcript: https://github.com/astral-sh/uv",
            file=sys.stderr,
        )
        sys.exit(1)

    # Intentionally not cleaned up — the browser needs the HTML files to persist after launch.
    out_dir = tempfile.mkdtemp(prefix=f"transcript-{str(s['session_id'])[:8]}-")
    print(f"Generating transcript for session {s['session_id']} ...")
    print(f"  Project: {s.get('cwd') or 'unknown'}")
    print(f"  Date:    {s.get('date')} {s.get('start_time')}")

    cmd = [*runner, "claude-code-transcripts", "json", jsonl_file, "-o", out_dir, "--open"]
    repo = _detect_github_repo(s.get("cwd"))
    if repo:
        cmd += ["--repo", repo]

    result = subprocess.run(cmd)
    if result.returncode != 0:
        print("Error: claude-code-transcripts failed.", file=sys.stderr)
        sys.exit(1)
