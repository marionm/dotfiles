#!/bin/bash

if [ -d ~/.vim-orig ]; then
  mv ~/.vim-orig ~/.vim
  mv ~/.vimrc-orig ~/.vimrc
else
  echo Nothing to restore!
  exit 1
fi
