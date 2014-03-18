#!/bin/bash

DIR=`dirname $0`
. $DIR/util.sh

if argument vim; then
  replace ~/.vim
  replace ~/.vimrc
  vim -c BundleInstall -c qa
fi

if argument irb; then
  replace ~/.irbrc
fi

if argument tmux; then
  replace ~/.tmux.conf
fi

if argument screen; then
  replace ~/.screenrc
fi

if argument git; then
  if ! grep -q '# start marionm' ~/.gitconfig; then
    echo '# start marionm' >> ~/.gitconfig
    cat $DIR/.gitconfig >> ~/.gitconfig
    echo '# end marionm' >> ~/.gitconfig
  fi
  cp $DIR/.git-completion.sh ~
  cp $DIR/.git-branch-prompt.sh ~
fi

if argument bash; then
  cp $DIR/.profile-marionm ~
  if ! grep -q profile-marionm ~/.bashrc; then
    echo 'if [ -f ~/.profile-marionm ]; then . ~/.profile-marionm; fi' >> ~/.bashrc
  fi
  . ~/.bashrc
fi
