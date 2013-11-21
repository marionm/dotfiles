#!/bin/bash

# Vim
if [ -d ~/.vim-orig ]; then
  mv ~/.vim-orig ~/.vim
fi
if [ -f ~/.vimrc-orig ]; then
  mv ~/.vimrc-orig ~/.vimrc
fi

# IRB
if [ -f ~/.irbrc-orig ]; then
  mv ~/.irbrc-orig ~/.irbrc
fi

# Git
sed -i '' '/# start marionm/,/# end marionm/d' ~/.gitconfig

# Bash
rm -f ~/.profile-marionm
