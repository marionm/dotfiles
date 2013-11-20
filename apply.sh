#!/bin/bash

DIR=`dirname $0`

# Vim
if [ ! -d ~/.vim-orig ]; then
  mv ~/.vim ~/.vim-orig
fi
if [ ! -f ~/.vimrc-orig ]; then
  mv ~/.vimrc ~/.vimrc-orig
fi
cp -R $DIR/.vim* ~

# Git
cp $DIR/.git-completion.sh ~
cp $DIR/.git-branch-prompt.sh ~

# Bash
cp $DIR/.profile-marionm ~
if ! grep -q profile-marionm ~/.bashrc; then
  echo 'if [ -f ~/.profile-marionm ]; then . ~/.profile-marionm; fi' >> ~/.bashrc
fi
. ~/.bashrc
