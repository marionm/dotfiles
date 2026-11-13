#!/bin/sh
# Close the current herdr workspace, offering to delete its worktree checkout when it has one.
set -e

# Runs in a popup that closes when this exits, so leave errors on screen until a key is pressed.
trap 'status=$?; if [ $status -ne 0 ]; then printf "\nFailed - press enter to close"; read -r _; fi' EXIT

# -D rather than -d: squash merges leave a merged branch looking unmerged to git, so -d would refuse.
delete_branch() {
  if [ -n "$branch" ]; then
    git -C "$main" branch -D "$branch"
  fi
}

# Commits on the branch whose changes were never pushed. Compared by patch rather than commit id, so a commit counts as
# pushed when the branch was rebased after it was checked out, or squash-merged and deleted from origin.
count_unpushed_commits() {
  if git -C "$checkout" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    pushed="origin/$branch"
  else
    pr_number=$(cd "$checkout" && gh pr list --head "$branch" --state all --json number --jq '.[0].number // empty' 2>/dev/null || true)
    if [ -z "$pr_number" ] || ! git -C "$checkout" fetch --quiet origin "pull/$pr_number/head" 2>/dev/null; then
      git -C "$checkout" rev-list --count HEAD --not --remotes
      return
    fi
    pushed=FETCH_HEAD
  fi
  default_branch=$(git -C "$checkout" symbolic-ref --quiet --short refs/remotes/origin/HEAD || echo origin/master)

  # Only the branch's own commits - a branch rebased onto a newer master would otherwise count master's new commits too.
  git -C "$checkout" cherry "$pushed" HEAD "$(git -C "$checkout" merge-base HEAD "$default_branch")" | grep -c '^+' || true
}

workspace="$HERDR_ACTIVE_WORKSPACE_ID"
info=$(herdr workspace get "$workspace" | jq .result.workspace)
label=$(echo "$info" | jq -r .label)
checkout=$(echo "$info" | jq -r 'select(.worktree.is_linked_worktree == true) | .worktree.checkout_path')

if [ -n "$checkout" ]; then
  main=$(dirname "$(git -C "$checkout" rev-parse --path-format=absolute --git-common-dir)")
  changes=$(git -C "$checkout" status --porcelain | wc -l | tr -d ' ')
  branch=$(git -C "$checkout" symbolic-ref --quiet --short HEAD || true)
  if [ -n "$branch" ]; then
    unpushed=$(count_unpushed_commits)
  else
    unpushed=$(git -C "$checkout" rev-list --count HEAD --not --remotes)
  fi

  # Claude Code locks the worktrees it creates while a session uses them, and doesn't always unlock them on exit.
  lock_reason=$(git -C "$main" worktree list --porcelain | awk -v tree="$checkout" '
    /^worktree / { current = substr($0, 10) }
    current == tree && /^locked/ { sub(/^locked ?/, ""); print ($0 == "" ? "no reason given" : $0); exit }
  ')

  other_workspaces=$(herdr pane list | jq -r --arg workspace "$workspace" --arg checkout "$checkout" '[.result.panes[] | select(.workspace_id != $workspace and ((.cwd | startswith($checkout)) or ((.foreground_cwd // "") | startswith($checkout)))) | .workspace_id] | unique | join(", ")')
  if [ -n "$other_workspaces" ]; then
    printf 'Another workspace (%s) is also open in this checkout - close it first, or what runs there may keep writing to it.\n' "$other_workspaces"
  fi

  needs_force=
  if [ "$changes" -gt 0 ] || [ "$unpushed" -gt 0 ] || [ -n "$lock_reason" ]; then
    needs_force=true
    if [ "$changes" -gt 0 ]; then
      printf '%s has %s uncommitted or untracked files.\n' "$label" "$changes"
    fi
    if [ "$unpushed" -gt 0 ]; then
      printf '%s has %s commits that were never pushed.\n' "$label" "$unpushed"
    fi
    if [ -n "$lock_reason" ]; then
      printf '%s is locked: %s\n' "$label" "$lock_reason"
    fi
    printf '  f - close and delete its worktree and branch anyway\n'
  else
    printf 'Close %s?\n' "$label"
    printf '  y - close and delete its worktree and branch\n'
  fi
  printf '  c - just close\n'
  printf '  anything else - cancel\n> '

  read -r answer
  # y is only offered when nothing would be lost, so it can't stand in for f.
  if [ "$needs_force" ] && [ "$answer" = y -o "$answer" = Y ]; then
    answer=
  fi

  case "$answer" in
    y|Y)
      # Close first: that stops what runs in the workspace, and a dev server left running keeps writing files into
      # the checkout while it's being deleted.
      herdr workspace close "$workspace" >/dev/null
      git -C "$main" worktree remove "$checkout"
      delete_branch
      ;;
    f|F)
      herdr workspace close "$workspace" >/dev/null
      if [ -n "$lock_reason" ]; then
        # A second --force is what overrides a lock.
        git -C "$main" worktree remove --force --force "$checkout"
      else
        git -C "$main" worktree remove --force "$checkout"
      fi
      delete_branch
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
