#!/usr/bin/env bash
set -euo pipefail

OS="$(uname -s)"
case "$OS" in
    Linux)
        HOSTNAME=$(hostnamectl hostname 2>/dev/null) || HOSTNAME=$(cat /etc/hostname 2>/dev/null) || HOSTNAME="unknown"
        ;;
    Darwin)
        HOSTNAME=$(scutil --get ComputerName 2>/dev/null) || HOSTNAME=$(hostname -s 2>/dev/null) || HOSTNAME="unknown"
        ;;
    *)
        HOSTNAME="unknown"
        ;;
esac

cat <<EOF
---
name: machine-context
description: Use when starting any session in the dotfiles repo - detects current machine and OS for context
---

## Machine Context

This session is running on:

- **Machine:** ${HOSTNAME}
- **OS:** ${OS}

**CRITICAL:** Do NOT run scripts, commands, or edit files for any other machine or OS unless explicitly instructed by the user. If you need to work on a different machine, ask the user first.
EOF
