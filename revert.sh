#!/bin/bash

. `dirname $0`/util.sh

if argument vim; then
  revert ~/.vim
  revert ~/.vimrc
fi

if argument pry; then
  revert ~/.pryrc
fi

if argument tmux; then
  revert ~/.tmux.conf
fi

if argument screen; then
  echo doit
  revert ~/.screenrc
fi

if argument git; then
  TARGET=~/.gitconfig
  TMP=/tmp/.gitconfig.marionm
  sed -e '/# start marionm/,/# end marionm/d' $TARGET > $TMP
  mv $TMP $TARGET
fi

if argument bash; then
  rm -f ~/.profile-marionm
fi

if argument zsh; then
  rm -f ~/.profile-marionm
fi

if argument hs; then
  revert ~/.hammerspoon/init.lua
fi
