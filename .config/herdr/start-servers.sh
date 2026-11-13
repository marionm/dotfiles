#!/bin/sh
# Open a "servers" tab in the current herdr workspace running rails, sidekiq, and the webpack dev server for the
# checkout, on the ports in its .env.development.local.
set -e

# The ACTIVE variables are set when a keybinding runs this; from a shell or an agent in a pane, it's that pane's own.
workspace="${HERDR_ACTIVE_WORKSPACE_ID:-$HERDR_WORKSPACE_ID}"
root=$(git -C "${HERDR_ACTIVE_PANE_CWD:-$PWD}" rev-parse --show-toplevel)

existing_tab=$(herdr tab list --workspace "$workspace" | jq -r '.result.tabs[] | select(.label | startswith("servers")) | "\(.tab_id) \(.label)"' | head -1)
if [ -n "$existing_tab" ]; then
  echo "Already running: ${existing_tab#* }"

  # Only jump to it when pressed - an agent running this shouldn't move what's on screen.
  if [ -n "$HERDR_ACTIVE_WORKSPACE_ID" ]; then
    herdr tab focus "${existing_tab%% *}" >/dev/null
  fi
  exit 0
fi

# The lowest value from $2 up that no worktree's .env.development.local sets with the prefix $1, and that, when $3 is
# set, nothing is listening on.
get_unclaimed_value() {
  claimed_values=$(git -C "$root" worktree list --porcelain | sed -n 's/^worktree //p' | while read -r tree; do
    sed -n "s|^$1||p" "$tree/.env.development.local" 2>/dev/null || true
  done)
  value=$2
  while echo "$claimed_values" | grep -qx "$value" || { [ -n "$3" ] && lsof -iTCP:"$value" -sTCP:LISTEN >/dev/null 2>&1; }; do
    value=$((value + 1))
  done
  echo "$value"
}

if ! lsof -iTCP:3000 -sTCP:LISTEN >/dev/null 2>&1; then
  # Nothing else is running, so take the defaults in place of this worktree's own ports and Redis db. dotenv-rails
  # doesn't overwrite variables that are already set, and the sidekiq initializer ignores an empty SIDEKIQ_REDIS_URL.
  rails_port=3000
  dev_server_port=3035
  env_overrides="PORT=3000 SHAKAPACKER_DEV_SERVER_PORT=3035 SIDEKIQ_REDIS_URL= "
elif [ -f "$root/.env.development.local" ]; then
  rails_port=$(sed -n 's/^PORT=//p' "$root/.env.development.local")
  dev_server_port=$(sed -n 's/^SHAKAPACKER_DEV_SERVER_PORT=//p' "$root/.env.development.local")
  env_overrides=""
else
  # The main checkout has no ports of its own to fall back on, so take the first ones no worktree has claimed - the
  # defaults went to whichever worktree started first.
  rails_port=$(get_unclaimed_value PORT= 3002 port)
  dev_server_port=$(get_unclaimed_value SHAKAPACKER_DEV_SERVER_PORT= 3036 port)
  redis_db=$(get_unclaimed_value SIDEKIQ_REDIS_URL=redis://localhost:6379/ 2)
  env_overrides="PORT=$rails_port SHAKAPACKER_DEV_SERVER_PORT=$dev_server_port SIDEKIQ_REDIS_URL=redis://localhost:6379/$redis_db "
fi

rails_pane=$(herdr tab create --workspace "$workspace" --cwd "$root" --label "servers :$rails_port" --no-focus | jq -r .result.root_pane.pane_id)

# herdr reports a failed request in its output rather than its exit status.
if [ "$rails_pane" = null ]; then
  echo "Couldn't create the servers tab in workspace $workspace" >&2
  exit 1
fi
sidekiq_pane=$(herdr pane split --pane "$rails_pane" --direction down --cwd "$root" --no-focus | jq -r .result.pane.pane_id)
dev_server_pane=$(herdr pane split --pane "$sidekiq_pane" --direction right --cwd "$root" --no-focus | jq -r .result.pane.pane_id)

herdr pane run "$rails_pane" "${env_overrides}bundle exec rails s -p $rails_port" >/dev/null
herdr pane run "$sidekiq_pane" "${env_overrides}bundle exec sidekiq -c 5" >/dev/null

# bin/shakapacker-dev-server doesn't read .env.development.local, so the port has to be passed in.
herdr pane run "$dev_server_pane" "SHAKAPACKER_DEV_SERVER_PORT=$dev_server_port bin/shakapacker-dev-server" >/dev/null

echo "Started: servers :$rails_port"
