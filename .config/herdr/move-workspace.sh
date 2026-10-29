#!/bin/sh
# Move the current herdr workspace up or down one place among its siblings in the sidebar - the other worktrees of its
# repo for a worktree, the top-level workspaces otherwise.
set -e

direction="$1"
workspace="$HERDR_ACTIVE_WORKSPACE_ID"
workspaces=$(herdr workspace list | jq .result.workspaces)

# Worktrees show grouped under their repo, but they sit in the same flat list as every other workspace, so the place to
# move to is next to the nearest sibling in that list, not the next row on screen.
repo_key=$(echo "$workspaces" | jq -r --arg id "$workspace" '.[] | select(.workspace_id == $id) | if .worktree.is_linked_worktree == true then .worktree.repo_key else "" end')
siblings=$(echo "$workspaces" | jq -r --arg key "$repo_key" '.[] | select(if $key == "" then .worktree.is_linked_worktree != true else .worktree.is_linked_worktree == true and .worktree.repo_key == $key end) | .workspace_id')

position=$(echo "$siblings" | grep -n -x "$workspace" | cut -d: -f1)
count=$(echo "$siblings" | wc -l | tr -d ' ')

case "$direction" in
  up)
    if [ "$position" -le 1 ]; then
      exit 0
    fi
    before=$(echo "$siblings" | sed -n "$((position - 1))p")
    ;;
  down)
    if [ "$position" -ge "$count" ]; then
      exit 0
    fi

    # Two places down, or the end of the list when it's moving past the last sibling.
    before=$(echo "$siblings" | sed -n "$((position + 2))p")
    ;;
  *)
    echo "usage: move-workspace.sh up|down" >&2
    exit 1
    ;;
esac

# The herdr CLI has no move command, so this goes straight to its socket.
jq -n -c --arg id "$workspace" --arg before "$before" \
  '{id: "move-workspace", method: "workspace.move_block", params: {workspace_ids: [$id], before_workspace_id: (if $before == "" then null else $before end)}}' \
  | nc -U -w 2 "$HERDR_SOCKET_PATH" >/dev/null
