Various configuration files, most notably for Vim and Git.

Clone and apply with:
```
git clone https://github.com/marionm/dotfiles
dotfiles/apply.sh
````

Pass any part of a path to apply just those files - for example, just git and vim:
```
dotfiles/apply.sh git vim
```

Revert with:
```
dotfiles/revert.sh
```

It removes the symlinks that point into this repo and restores the `-orig` backups. It takes the same path filters as
`apply.sh`.

## Ghostty + herdr

[herdr](https://herdr.dev) runs in its own Ghostty instance, separate from regular Ghostty windows, so it can take over
Cmd shortcuts there without breaking them everywhere else. Launch via Herdr.app, packed this way so that it is indexed
by OSX Spotlight. To apply just this part:
```
dotfiles/apply.sh ghostty herdr hunk Herdr.app
```
