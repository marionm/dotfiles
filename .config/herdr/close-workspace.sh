#!/bin/sh
# Close the current herdr workspace, offering to delete its worktree checkout when it has one.
set -e

# Runs in a popup that closes when this exits, so leave errors on screen until a key is pressed.
trap 'status=$?; if [ $status -ne 0 ]; then printf "\nFailed - press enter to close"; read -r _; fi' EXIT

workspace="$HERDR_ACTIVE_WORKSPACE_ID"
info=$(herdr workspace get "$workspace" | jq .result.workspace)
label=$(echo "$info" | jq -r .label)
checkout=$(echo "$info" | jq -r 'select(.worktree.is_linked_worktree == true) | .worktree.checkout_path')

if [ -n "$checkout" ]; then
  main=$(dirname "$(git -C "$checkout" rev-parse --path-format=absolute --git-common-dir)")
  changes=$(git -C "$checkout" status --porcelain | wc -l | tr -d ' ')

  other_workspaces=$(herdr pane list | jq -r --arg workspace "$workspace" --arg checkout "$checkout" '[.result.panes[] | select(.workspace_id != $workspace and ((.cwd | startswith($checkout)) or ((.foreground_cwd // "") | startswith($checkout)))) | .workspace_id] | unique | join(", ")')
  if [ -n "$other_workspaces" ]; then
    printf 'Another workspace (%s) is also open in this checkout - close it first, or what runs there may keep writing to it.\n' "$other_workspaces"
  fi

  if [ "$changes" -gt 0 ]; then
    printf '%s has %s uncommitted or untracked files.\n' "$label" "$changes"
    printf '  f - close and delete its worktree anyway, losing them\n'
  else
    printf 'Close %s?\n' "$label"
    printf '  y - close and delete its worktree\n'
  fi
  printf '  c - just close\n'
  printf '  anything else - cancel\n> '

  read -r answer
  case "$answer" in
    y|Y)
      # Close first: that stops what runs in the workspace, and a dev server left running keeps writing files into
      # the checkout while it's being deleted. Removing leaves the branch alone.
      herdr workspace close "$workspace" >/dev/null
      git -C "$main" worktree remove "$checkout"
      ;;
    f|F)
      herdr workspace close "$workspace" >/dev/null
      git -C "$main" worktree remove --force "$checkout"
      ;;
    c|C)
      herdr workspace close "$workspace" >/dev/null
      ;;
  esac
else
  printf 'Close %s? [y/N] ' "$label"
  read -r answer
  case "$answer" in
    y|Y)
      herdr workspace close "$workspace" >/dev/null
      ;;
  esac
fi
