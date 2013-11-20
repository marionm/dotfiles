#bash
function parse_git_branch {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

function proml {
  local BRANCH="\[\033[0;35m\]"
  local  BLACK="\[\033[0;30m\]"
  PS1="$BLACK\u@\h:\W$BRANCH\$(parse_git_branch)$BLACK\$ "
}

proml

