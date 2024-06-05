#!/bin/bash

##
# Script to inject the java version found on the path into the repo information
# on the tmux status.
#
# Note: if the shell PATH is different than the PATH that tmux sees and that
# results in a different java env, then you'll need to update the tmux
# PROMPT_COMMAND to include (see .tmux-status-right for more info):
#
#   tmux setenv TMUXPATH_$(tmux display -p "#I_#P") "$PATH"
##

var=$(tmux display -p "TMUXPATH_#I_#P")
val=$(tmux show-environment $var 2> /dev/null)

# tmux show-environment prior to 1.7 doesn't support showing a single var
if [ -z "$val" ] ; then
  val=$(tmux show-environment | grep "^$var=")
fi

if [ -n "$val" ] ; then
  eval $val
  PATH=${!var}
fi

repo="$1"
if $(PATH=$PATH which java > /dev/null 2>&1); then
  version=$(
    PATH=$PATH java -version 2>&1 |
      grep version |
      perl -pe 's|.*"([0-9].*)".*|\1|'
  )
  if [[ "$version" == 1.* ]] ; then
    version=$(echo $version | perl -pe 's|1\.(.*)\..*|\1|')
  else
    version=$(echo $version | perl -pe 's|([0-9]+)\..*|\1|')
  fi

  repo=$(echo $repo | perl -pe "s|(.*):(.*)|\\1(java$version):\\2|")
fi

echo $repo

# vim:ft=bash
