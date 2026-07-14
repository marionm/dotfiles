#!/usr/bin/env bash
# Remove symlinks this repo placed in $HOME and restore any *-orig backups.
#   ./revert.sh            revert everything
#   ./revert.sh vim claude only tracked paths containing one of these substrings
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

filters=("$@")
git ls-files | while IFS= read -r f; do
  dest="$HOME/$f"
  if [ ${#filters[@]} -gt 0 ]; then
    match=""
    for needle in "${filters[@]}"; do
      case "$f" in *"$needle"*) match=1 ;; esac
    done
    if [ -z "$match" ]; then
      continue
    fi
  fi
  # only touch symlinks that point back into this repo
  if [ -L "$dest" ]; then
    case "$(readlink "$dest")" in
      "$DIR"/*)
        rm "$dest"
        if [ -e "$dest-orig" ]; then
          mv "$dest-orig" "$dest"
        fi
        echo "unlinked ~/$f"
        ;;
    esac
  fi
done
