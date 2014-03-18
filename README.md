Various configuration files, most notably for Vim and Git.

Clone and apply with:
```
git clone https://github.com/marionm/dotfiles
dotfiles/apply.sh
````

The apply script will take arguments if only some changes are desired. For example, to apply only vim and tmux:
```
dotfiles/apply.sh vim tmux
```

Revert with:
```
dotfiles/revert.sh
```
