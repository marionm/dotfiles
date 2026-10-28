#!/usr/bin/env bash
# Symlink every tracked dotfile into $HOME.
#   ./apply.sh             apply everything tracked (minus the excludes below)
#   ./apply.sh vim claude  only tracked paths containing one of these substrings
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

# Tracked but NOT symlinked into $HOME:
#   repo infra      - the installer itself, readme, submodule metadata
#   manual import   - browser CSS (imported via the browser)
#   top-level dupes - find-importers{,.ts} are copies of the .local/bin versions that go on PATH
#   per-machine     - ~/.claude/settings.json stays a real file (model/vim/plugins differ per box)
is_excluded() {
  case "$1" in
    apply.sh|revert.sh|README.md|.gitmodules) return 0 ;;
    css/*) return 0 ;;
    find-importers|find-importers.ts) return 0 ;;
    .claude/settings.json) return 0 ;;
  esac
  return 1
}

# symlink $DIR/$1 -> ~/$1, backing up a pre-existing real file once (as the old replace() did)
link() {
  local src="$DIR/$1" dest="$HOME/$1"
  if [ -L "$dest" ]; then
    ln -sfn "$src" "$dest"
  else
    if [ -e "$dest" ] && [ ! -e "$dest-orig" ]; then
      mv "$dest" "$dest-orig"
    fi
    rm -rf "$dest"
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
  fi
}

# one-time: lift the machine-specific tail out of an old marker-merged ~/.gitconfig into
# ~/.gitconfig.local, which the tracked .gitconfig now [include]s last (no-op on a fresh box).
if [ ! -e "$HOME/.gitconfig.local" ] && [ -f "$HOME/.gitconfig" ] && grep -q '# end marionm' "$HOME/.gitconfig"; then
  sed -n '/# end marionm/,$p' "$HOME/.gitconfig" | sed '1d' > "$HOME/.gitconfig.local"
  echo "migrated machine-specific git config -> ~/.gitconfig.local"
fi

filters=("$@")
git ls-files | while IFS= read -r f; do
  if is_excluded "$f"; then
    continue
  fi
  if [ ${#filters[@]} -gt 0 ]; then
    match=""
    for needle in "${filters[@]}"; do
      case "$f" in *"$needle"*) match=1 ;; esac
    done
    if [ -z "$match" ]; then
      continue
    fi
  fi
  link "$f"
  echo "linked  ~/$f"
done

# symlinks can't do this: have the machine's shell rc source our profile
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -e "$rc" ] || continue
  if ! grep -q profile-marionm "$rc"; then
    echo 'if [ -f ~/.profile-marionm ]; then . ~/.profile-marionm; fi' >> "$rc"
  fi
done

# vim plugin manager (dein) lives in a submodule
git submodule update --init
