#!/bin/bash

revert() {
  if [ -d $1-orig ]; then
    mv $1-orig $1
  fi
}

revert ~/.vim
revert ~/.vimrc
revert ~/.irbrc
revert ~/.tmux.conf
revert ~/.screenrc

sed -i '' '/# start marionm/,/# end marionm/d' ~/.gitconfig

rm -f ~/.profile-marionm
