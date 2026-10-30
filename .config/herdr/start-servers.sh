#!/bin/sh
# Open a "servers" tab in the current herdr workspace running rails, sidekiq, and the webpack dev server for the
# checkout, on the ports in its .env.development.local.
set -e

workspace="$HERDR_ACTIVE_WORKSPACE_ID"
root=$(git -C "${HERDR_ACTIVE_PANE_CWD:-$PWD}" rev-parse --show-toplevel)

existing_tab=$(herdr tab list --workspace "$workspace" | jq -r '.result.tabs[] | select(.label | startswith("servers")) | .tab_id' | head -1)
if [ -n "$existing_tab" ]; then
  herdr tab focus "$existing_tab" >/dev/null
  exit 0
fi

if lsof -iTCP:3000 -sTCP:LISTEN >/dev/null 2>&1; then
  rails_port=$(sed -n 's/^PORT=//p' "$root/.env.development.local" 2>/dev/null)
  rails_port=${rails_port:-3000}
  dev_server_port=$(sed -n 's/^SHAKAPACKER_DEV_SERVER_PORT=//p' "$root/.env.development.local" 2>/dev/null)
  dev_server_port=${dev_server_port:-3035}
  env_overrides=""
else
  # Nothing else is running, so take the defaults in place of this worktree's own ports and Redis db. dotenv-rails
  # doesn't overwrite variables that are already set, and the sidekiq initializer ignores an empty SIDEKIQ_REDIS_URL.
  rails_port=3000
  dev_server_port=3035
  env_overrides="PORT=3000 SHAKAPACKER_DEV_SERVER_PORT=3035 SIDEKIQ_REDIS_URL= "
fi

rails_pane=$(herdr tab create --workspace "$workspace" --cwd "$root" --label "servers :$rails_port" --no-focus | jq -r .result.root_pane.pane_id)
sidekiq_pane=$(herdr pane split --pane "$rails_pane" --direction down --cwd "$root" --no-focus | jq -r .result.pane.pane_id)
dev_server_pane=$(herdr pane split --pane "$sidekiq_pane" --direction right --cwd "$root" --no-focus | jq -r .result.pane.pane_id)

herdr pane run "$rails_pane" "${env_overrides}bundle exec rails s -p $rails_port" >/dev/null
herdr pane run "$sidekiq_pane" "${env_overrides}bundle exec sidekiq -c 5" >/dev/null

# bin/shakapacker-dev-server doesn't read .env.development.local, so the port has to be passed in.
herdr pane run "$dev_server_pane" "SHAKAPACKER_DEV_SERVER_PORT=$dev_server_port bin/shakapacker-dev-server" >/dev/null
