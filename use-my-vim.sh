#!/bin/bash

if [ -d ~/.vim-orig ]; then
  echo Already using my vim config!
  exit 1
else
  mv ~/.vim ~/.vim-orig
  mv ~/.vimrc ~/.vimrc-orig
  cp -R `dirname $0`/.vim* ~
fi
