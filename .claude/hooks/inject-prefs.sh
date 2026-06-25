#!/usr/bin/env bash
# PreToolUse (Edit|Write|MultiEdit) hook: inject Mike's prefs skills as additionalContext.
# general-prefs on code/config edits (not docs/data/generated); ruby-prefs / js-prefs by extension.
set -euo pipefail

SKILLS="$HOME/.claude/skills"
input="$(cat)"
file="$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')"

if [ -z "$file" ]; then
  exit 0
fi

parts=()

# general-prefs: code and config, but skip prose/data/generated files where none of it applies
case "$file" in
  *.md|*.markdown|*.mdx|*.txt|*.rst|*.adoc|*.csv|*.tsv|*.log|*.svg|*.snap) ;;
  *.lock|*-lock.json|*/yarn.lock|*/Gemfile.lock|*/package-lock.json) ;;
  *) parts+=("$SKILLS/general-prefs/SKILL.md") ;;
esac

case "$file" in
  *.rb) parts+=("$SKILLS/ruby-prefs/SKILL.md") ;;
  *.js|*.jsx|*.ts|*.tsx) parts+=("$SKILLS/js-prefs/SKILL.md") ;;
esac

if [ ${#parts[@]} -eq 0 ]; then
  exit 0
fi

context=""
for p in "${parts[@]}"; do
  if [ -f "$p" ]; then
    context+="$(cat "$p")"$'\n\n'
  fi
done

if [ -z "$context" ]; then
  exit 0
fi

jq -n --arg ctx "$context" \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $ctx}}'
