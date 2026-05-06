#!/usr/bin/env python3
"""
analyze-usage.py — shim that delegates to the analyze_usage package.

The actual implementation lives in analyze_usage/ alongside this file.
Run `python3 analyze-usage.py --help` for full usage.
"""

import sys
from pathlib import Path

# Ensure the scripts/ directory is on the path so the package is importable
# regardless of the caller's working directory.
sys.path.insert(0, str(Path(__file__).parent))

from analyze_usage.cli import main

if __name__ == "__main__":
    main()
