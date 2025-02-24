#!/bin/bash

DIR=`dirname $0`
. $DIR/util.sh

if argument vim; then
  (cd $DIR ; git submodule update --init)
  replace ~/.vim
  replace ~/.vimrc
fi

if argument nvim; then
  (cd $DIR ; git submodule update --init)
  mkdir -p ~/.config/nvim
  replace ~/.config/nvim/init.vim
  replace ~/.nvim_iterm2_runner
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

  touch ~/.gitconfig
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

  touch ~/.bashrc
  if ! grep -q profile-marionm ~/.bashrc; then
    echo 'if [ -f ~/.profile-marionm ]; then . ~/.profile-marionm; fi' >> ~/.bashrc
  fi

  . ~/.bashrc
fi

if argument zsh; then
  cp $DIR/.profile-marionm ~

  touch ~/.zshrc
  if ! grep -q profile-marionm ~/.zshrc; then
    echo 'if [ -f ~/.profile-marionm ]; then . ~/.profile-marionm; fi' >> ~/.zshrc
  fi

  . ~/.zshrc
fi

if argument hs; then
  mkdir -p ~/.hammerspoon
  replace ~/.hammerspoon/init.lua
fi
