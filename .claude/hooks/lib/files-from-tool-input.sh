#!/usr/bin/env bash
# Reads a hook's JSON payload on stdin, prints the file paths the tool call writes to.
#
# Bash needs sniffing because auto mode edits through heredocs and sed rather than the Write/Edit
# tools. Only write-shaped commands count - reading or grepping a file is not touching it.
set -euo pipefail

EXT="rb|rake|erb|slim|js|jsx|ts|tsx|scss|css|json|ya?ml"
PATHISH="[^[:space:]'\";|&<>()]+"

input="$(cat)"
tool="$(printf '%s' "$input" | jq -r '.tool_name // ""')"

if [ "$tool" != "Bash" ]; then
  printf '%s' "$input" | jq -r '.tool_input.file_path // ""'
  exit 0
fi

cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"

# A redirect names its target, so only the path right after it counts - otherwise every
# `rspec spec/foo_spec.rb 2>&1 | tail` would look like a write.
files="$(printf '%s' "$cmd" | grep -oE ">>?[[:space:]]*$PATHISH\.($EXT)" \
  | grep -oE "$PATHISH\.($EXT)" || true)"

# These write files the regex cannot localize, so every code path in the command counts.
case "$cmd" in
  *"sed -i"*|*"tee "*|*"cp "*|*"mv "*|*python*"<<"*|*ruby*"<<"*|*perl*"<<"*)
    files="$files"$'\n'"$(printf '%s' "$cmd" | grep -oE "$PATHISH\.($EXT)" || true)" ;;
esac

printf '%s\n' "$files"
