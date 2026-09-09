#!/usr/bin/env bash
# PostToolUse hook: record which files this session wrote, so the Stop-time prefs audit runs only
# on turns that produced something and looks only at what this session actually touched.
#
# Without this the gate fires on any change to the session diff - a migration rewriting schema.rb,
# a branch switch, Mike editing in his own editor - and hands over other people's work to audit.
set -euo pipefail

STATE_DIR="$HOME/.claude/state/prefs-review"

input="$(cat)"
session="$(printf '%s' "$input" | jq -r '.session_id // "unknown"')"
cwd="$(printf '%s' "$input" | jq -r '.cwd // ""')"

files="$(printf '%s' "$input" | "$HOME/.claude/hooks/lib/files-from-tool-input.sh")"

if [ -z "$(printf '%s\n' "$files" | "$HOME/.claude/hooks/lib/prefs-for-files.sh")" ]; then
  exit 0
fi

mkdir -p "$STATE_DIR"

# Absolute, because a bash-sniffed path is relative to the cwd of the call that wrote it and the
# audit runs later from wherever the session happens to sit.
while IFS= read -r file; do
  case "$file" in
    "") ;;
    /*) printf '%s\n' "$file" >> "$STATE_DIR/$session.written" ;;
    *) printf '%s/%s\n' "${cwd:-$PWD}" "$file" >> "$STATE_DIR/$session.written" ;;
  esac
done <<< "$files"
