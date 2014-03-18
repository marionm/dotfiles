#!/bin/bash

. `dirname $0`/util.sh

if argument vim; then
  revert ~/.vim
  revert ~/.vimrc
fi

if argument irb; then
  revert ~/.irbrc
fi

if argument tmux; then
  revert ~/.tmux.conf
fi

if argument screen; then
  echo doit
  revert ~/.screenrc
fi

if argument git; then
  sed -i '' '/# start marionm/,/# end marionm/d' ~/.gitconfig
fi

if argument bash; then
  rm -f ~/.profile-marionm
fi
