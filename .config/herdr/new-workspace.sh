#!/bin/sh
# Open a herdr workspace in the current directory with claude, hunk, and shell tabs.
set -e

cwd="${HERDR_ACTIVE_PANE_CWD:-$PWD}"

created=$(herdr workspace create --cwd "$cwd" --focus)
workspace=$(echo "$created" | jq -r .result.workspace.workspace_id)
claude_tab=$(echo "$created" | jq -r .result.tab.tab_id)
claude_pane=$(echo "$created" | jq -r .result.root_pane.pane_id)

herdr tab rename "$claude_tab" claude >/dev/null
herdr pane run "$claude_pane" claude >/dev/null

diff_pane=$(herdr tab create --workspace "$workspace" --cwd "$cwd" --label diff --no-focus | jq -r .result.root_pane.pane_id)
herdr pane run "$diff_pane" "hunk diff --watch" >/dev/null

herdr tab create --workspace "$workspace" --cwd "$cwd" --label shell --no-focus >/dev/null
