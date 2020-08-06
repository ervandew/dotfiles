#!bash
#
# Extension to the main git bash completion script to add support for custom
# aliases of mine.

GIT_COMPLETION=/usr/share/git/completion/git-completion.bash
if [ ! -f $GIT_COMPLETION ] ; then
  GIT_COMPLETION=/System/Volumes/Data/opt/local/share/git/contrib/completion/git-completion.bash
fi

if [ ! -f $GIT_COMPLETION ] ; then
  return
fi

source $GIT_COMPLETION

# http://mivok.net/2009/09/20/bashfunctionoverrist.html
save_function() {
  local ORIG_FUNC=$(declare -f $1)
  local NEWNAME_FUNC="$2${ORIG_FUNC#$1}"
  eval "$NEWNAME_FUNC"
}

save_function __git_aliased_command __git_aliased_command_orig

__git_aliased_command() {
  case "$1" in
    blog | blogin | blogout)
      echo "log" ; return ;;
    dbranch | mergein | rebasesafe)
      echo "branch" ; return ;;
    ghcompare | glcompare | glpullrequest)
      echo "branch" ; return ;;
  esac

  # handle pick aliases
  rhs=$(git --git-dir="$(__gitdir)" config --get "alias.$1" | perl -pe 's|\\||g')
  pick=\\bpick\\b
  if [[ "$rhs" =~ $pick ]] ; then
    list=\\\|
    if [[ "$rhs" =~ $list ]] ; then
      # list aliases
      cmd=$(echo $rhs | perl -pe 's|.*?git\s+(?:-\S+\s+\S+\s+)*([a-zA-Z0-9-_]+).*|\1|')
      if [ "$cmd" != "$rhs" ] ; then
        echo "$cmd"
        return
      fi
    else
      # aliases acting on lists
      cmd=$(echo $rhs | perl -pe 's/.*\bpick\s+((-v|-c|-t\s+\w+)\s+){0,}([a-zA-Z0-9-_]+).*/\3/')
      if [ "$cmd" != "$rhs" ] ; then
        echo "$cmd"
        return
      fi
    fi
  fi

  __git_aliased_command_orig "$@"
}

_git_dstash() {
  __gitcomp "$(git --git-dir="$(__gitdir)" stash list | sed -n -e 's/:.*//p')"
}
