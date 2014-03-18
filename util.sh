#!/bin/bash

arguments=$@
argument() {
  [[ -z $arguments || $arguments =~ ${1} ]]
}

replace() {
  if [ -e $1 ] && [ ! -e $1-orig ]; then
    mv $1 $1-orig
  fi
  rm -rf $1
  cp -R `dirname $0`/`basename $1` `dirname $1`
}

revert() {
  rm -rf $1
  if [ -e $1-orig ]; then
    mv $1-orig $1
  fi
}
