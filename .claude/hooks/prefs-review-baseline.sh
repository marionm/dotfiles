#!/usr/bin/env bash
# SessionStart hook: record where the repo stood when this session began, so the Stop-time prefs
# audit can scope itself to what this session changed rather than to everything on the branch.
set -euo pipefail

STATE_DIR="$HOME/.claude/state/prefs-review"

input="$(cat)"
session="$(printf '%s' "$input" | jq -r '.session_id // "unknown"')"
cwd="$(printf '%s' "$input" | jq -r '.cwd // ""')"

if [ -n "$cwd" ]; then
  cd "$cwd" || exit 0
fi

if ! head="$(git rev-parse HEAD 2>/dev/null)"; then
  exit 0
fi

mkdir -p "$STATE_DIR"
printf '%s' "$head" > "$STATE_DIR/$session.base"
