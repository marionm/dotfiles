#!/bin/bash

DIR=`dirname $0`
. $DIR/util.sh

if argument vim; then
  (cd $DIR ; git submodule update --init)
  replace ~/.vim
  replace ~/.vimrc
fi

if argument pry; then
  replace ~/.pryrc
fi

if argument tmux; then
  replace ~/.tmux.conf
fi

if argument screen; then
  replace ~/.screenrc
fi

if argument git; then
  $DIR/revert.sh git

  cp ~/.gitconfig ~/.gitconfig.original

  echo '# start marionm' > ~/.gitconfig
  cat $DIR/.gitconfig >> ~/.gitconfig
  echo '# end marionm' >> ~/.gitconfig
  cat ~/.gitconfig.original >> ~/.gitconfig

  rm ~/.gitconfig.original

  cp $DIR/.git-completion.sh ~
  cp $DIR/.git-branch-helper ~
  cp $DIR/.git-branch-prompt.sh ~
fi

if argument bash; then
  cp $DIR/.profile-marionm ~
  if ! grep -q profile-marionm ~/.bashrc; then
    echo 'if [ -f ~/.profile-marionm ]; then . ~/.profile-marionm; fi' >> ~/.bashrc
  fi
  . ~/.bashrc
fi
