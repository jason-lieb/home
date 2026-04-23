#!/usr/bin/env bash
# extract-chats.sh
# Extracts conversation summaries from Claude Code and opencode for skill gap analysis.
# Usage: extract-chats.sh [--limit N]  (default: 50 sessions per tool)

set -euo pipefail

LIMIT=50

while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit)
      LIMIT="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

CLAUDE_PROJECTS_DIR="${HOME}/.claude/projects"
OPENCODE_DB="${HOME}/.local/share/opencode/opencode.db"

extract_claude_code() {
  if [[ ! -d "$CLAUDE_PROJECTS_DIR" ]]; then
    echo "[claude-code] No projects directory found at $CLAUDE_PROJECTS_DIR — skipping." >&2
    return
  fi

  local count=0
  while IFS= read -r jsonl_file; do
    [[ $count -ge $LIMIT ]] && break

    local session_id
    session_id=$(basename "$jsonl_file" .jsonl)

    local user_messages
    user_messages=$(jq -r '
      select(.type == "user") |
      .message.content |
      if type == "string" then .
      elif type == "array" then map(select(.type == "text") | .text) | join(" ")
      else empty
      end
    ' "$jsonl_file" 2>/dev/null | tr '\n' ' ' | cut -c1-600)

    [[ -z "$user_messages" ]] && continue

    local skills_used
    skills_used=$(jq -r '
      select(.type == "assistant") |
      .message.content[]? |
      select(.type == "tool_use" and .name == "Skill") |
      .input.name
    ' "$jsonl_file" 2>/dev/null | sort -u | paste -sd ', ' -)

    echo "=== [claude-code] session: $session_id ==="
    echo "skills-loaded: ${skills_used:-none}"
    echo "user-requests: $user_messages"
    echo ""

    (( count++ )) || true
  done < <(find "$CLAUDE_PROJECTS_DIR" -name "*.jsonl" -type f | sort -r | head -n "$LIMIT")
}

extract_opencode() {
  if [[ ! -f "$OPENCODE_DB" ]]; then
    echo "[opencode] No database found at $OPENCODE_DB — skipping." >&2
    return
  fi

  if ! command -v sqlite3 &>/dev/null; then
    echo "[opencode] sqlite3 not found — skipping opencode extraction." >&2
    return
  fi

  local rows
  rows=$(sqlite3 -separator $'\x01' "$OPENCODE_DB" "
    SELECT
      p.session_id,
      COALESCE((
        SELECT GROUP_CONCAT(substr(json_extract(p2.data, '$.text'), 1, 300), ' ')
        FROM part p2
        JOIN message m2 ON p2.message_id = m2.id
        WHERE p2.session_id = p.session_id
          AND json_extract(m2.data, '$.role') = 'user'
          AND json_extract(p2.data, '$.type') = 'text'
      ), ''),
      COALESCE((
        SELECT GROUP_CONCAT(json_extract(p3.data, '$.state.input.name'), ', ')
        FROM part p3
        WHERE p3.session_id = p.session_id
          AND json_extract(p3.data, '$.type') = 'tool'
          AND json_extract(p3.data, '$.tool') = 'skill'
      ), '')
    FROM (
      SELECT DISTINCT session_id, MAX(time_created) as last_active
      FROM part
      GROUP BY session_id
      ORDER BY last_active DESC
      LIMIT ${LIMIT}
    ) p
    ORDER BY p.last_active DESC;
  " 2>/dev/null) || {
    echo "[opencode] Failed to query database." >&2
    return
  }

  while IFS=$'\x01' read -r session_id user_text skills_loaded; do
    [[ -z "$session_id" ]] && continue
    echo "=== [opencode] session: $session_id ==="
    echo "skills-loaded: ${skills_loaded:-none}"
    echo "user-requests: ${user_text:-<no text found>}"
    echo ""
  done <<< "$rows"
}

echo "--- Claude Code sessions ---"
extract_claude_code

echo "--- Opencode sessions ---"
extract_opencode
