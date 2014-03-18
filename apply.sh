#!/bin/bash

DIR=`dirname $0`

backup() {
  if [ -d $1 ] && [ ! -d $1-orig ]; then
    mv $1 $1-orig
  fi
}

backup ~/.vim
backup ~/.vimrc
rm -rf ~/.vim
cp -R $DIR/.vim* ~
vim -c BundleInstall -c qa

backup ~/.irbrc
cp $DIR/.irbrc ~

backup ~/.tmux.conf
cp $DIR/.tmux.conf ~

backup ~/.screenrc
cp $DIR/.screenrc ~

if ! grep -q '# start marionm' ~/.gitconfig; then
  echo '# start marionm' >> ~/.gitconfig
  cat $DIR/.gitconfig >> ~/.gitconfig
  echo '# end marionm' >> ~/.gitconfig
fi
cp $DIR/.git-completion.sh ~
cp $DIR/.git-branch-prompt.sh ~

cp $DIR/.profile-marionm ~
if ! grep -q profile-marionm ~/.bashrc; then
  echo 'if [ -f ~/.profile-marionm ]; then . ~/.profile-marionm; fi' >> ~/.bashrc
fi
. ~/.bashrc
