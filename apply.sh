#!/bin/bash

# Vim
if [ ! -d ~/.vim-orig ]; then
  mv ~/.vim ~/.vim-orig
fi
if [ ! -f ~/.vimrc-orig ]; then
  mv ~/.vimrc ~/.vimrc-orig
fi
cp -R `dirname $0`/.vim* ~
