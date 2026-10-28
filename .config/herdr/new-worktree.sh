#!/bin/sh
# Open a branch's worktree as a herdr workspace with claude, hunk, and shell tabs, creating the worktree if needed.
set -e

# Runs in a popup that closes when this exits, so leave errors on screen until a key is pressed.
trap 'status=$?; if [ $status -ne 0 ]; then printf "\nFailed - press enter to close"; read -r _; fi' EXIT

set_up_tabs() {
  workspace=$(echo "$1" | jq -r .result.workspace.workspace_id)
  claude_tab=$(echo "$1" | jq -r .result.tab.tab_id)
  claude_pane=$(echo "$1" | jq -r .result.root_pane.pane_id)
  checkout="$2"

  herdr tab rename "$claude_tab" claude >/dev/null
  herdr pane run "$claude_pane" claude >/dev/null

  diff_pane=$(herdr tab create --workspace "$workspace" --cwd "$checkout" --label diff --no-focus | jq -r .result.root_pane.pane_id)
  # Against the merge base rather than $base itself, so commits that landed on $base since the branch was cut don't
  # show up as changes.
  herdr pane run "$diff_pane" "hunk diff $(git -C "$checkout" merge-base "$base" HEAD) --watch" >/dev/null

  herdr tab create --workspace "$workspace" --cwd "$checkout" --label shell --no-focus >/dev/null
}

cd "${HERDR_ACTIVE_PANE_CWD:-$PWD}"

printf 'Branch: '
read -r branch
if [ -z "$branch" ]; then
  exit 0
fi

base=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo HEAD)

existing=$(herdr worktree list --cwd "$PWD" | jq -r --arg branch "$branch" '.result.worktrees[] | select(.branch == $branch)')
if [ -n "$existing" ]; then
  checkout=$(echo "$existing" | jq -r .path)

  # Opening a checkout another workspace already has would only focus that workspace, so start a separate one there.
  if [ "$(echo "$existing" | jq -r '.open_workspace_id // empty')" ]; then
    set_up_tabs "$(herdr workspace create --cwd "$checkout" --focus)" "$checkout"
  else
    set_up_tabs "$(herdr worktree open --cwd "$PWD" --branch "$branch" --focus)" "$checkout"
  fi
  exit 0
fi

if [ "$base" != HEAD ]; then
  git fetch --quiet origin "${base#origin/}"
fi

# herdr only checks out branches that exist locally, so a branch that's only on GitHub would otherwise come out as a
# new branch off the default one.
start="$base"
if ! git show-ref --verify --quiet "refs/heads/$branch" && git fetch --quiet origin "$branch" 2>/dev/null; then
  start="origin/$branch"
fi

created=$(herdr worktree create --cwd "$PWD" --branch "$branch" --base "$start" --focus)
checkout=$(echo "$created" | jq -r '.result.worktree.path // .result.workspace.worktree.checkout_path')
if [ "$start" = "origin/$branch" ]; then
  git -C "$checkout" branch --quiet --set-upstream-to "$start"
fi
set_up_tabs "$created" "$checkout"
