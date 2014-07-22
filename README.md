Various configuration files, most notably for Vim and Git.

Clone and apply with:
```
git clone https://github.com/marionm/dotfiles
dotfiles/apply.sh
````

The apply script will reconfigure everything by default, or it can take any of `bash`, `git`, `irb`, `screen`, `tmux`, and `vim` as arguments. For example, to apply only git and vim:
```
dotfiles/apply.sh git vim
```

Revert with:
```
dotfiles/revert.sh
```
