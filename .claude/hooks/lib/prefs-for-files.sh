#!/usr/bin/env bash
# Reads file paths on stdin, prints the prefs SKILL.md path if any of them is code or config.
#
# One skill covers every language now, so this only answers "is there anything here worth
# auditing" - prose, data and generated files are not.
set -euo pipefail

SKILL="$HOME/.claude/skills/prefs/SKILL.md"

while IFS= read -r file; do
  case "$file" in
    "") ;;
    *.md|*.markdown|*.mdx|*.txt|*.rst|*.adoc|*.csv|*.tsv|*.log|*.svg|*.snap) ;;
    *.lock|*-lock.json|*/yarn.lock|*/Gemfile.lock|*/package-lock.json) ;;
    *)
      if [ -f "$SKILL" ]; then
        printf '%s\n' "$SKILL"
      fi
      exit 0 ;;
  esac
done
