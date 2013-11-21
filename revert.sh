#!/bin/bash

# Vim
if [ -d ~/.vim-orig ]; then
  mv ~/.vim-orig ~/.vim
fi
if [ -f ~/.vimrc-orig ]; then
  mv ~/.vimrc-orig ~/.vimrc
fi

# Git
sed -i '' '/# start marionm/,/# end marionm/d' ~/.gitconfig

# Bash
rm -f ~/.profile-marionm
