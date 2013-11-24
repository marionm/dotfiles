#bash
function parse_git_branch {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

function proml {
  local BRANCH="\[\e[35m\]"
  local  RESET="\[\e[0m\]"
  PS1="$RESET\u@\h:\W$BRANCH\$(parse_git_branch)$RESET\$ "
}

proml

