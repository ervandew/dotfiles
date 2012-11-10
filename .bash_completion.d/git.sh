#!bash
#
# Extension to the main git bash completion script to add support for custom
# aliases of mine.

source /usr/share/git/completion/git-completion.bash

# http://mivok.net/2009/09/20/bashfunctionoverride.html
save_function() {
  local ORIG_FUNC=$(declare -f $1)
  local NEWNAME_FUNC="$2${ORIG_FUNC#$1}"
  eval "$NEWNAME_FUNC"
}

save_function __git_aliased_command __git_aliased_command_orig

__git_aliased_command() {
  case "$1" in
    blog | blogin | blogout)
      echo "log"
      return
      ;;
    codb)
      echo "branch"
      return
      ;;
    dbranch | mergein | rebasesafe)
      echo "branch"
      return
      ;;
    ghcompare)
      echo "branch"
      return
      ;;
  esac
  __git_aliased_command_orig "$@"
}

_git_dstash() {
  __gitcomp "$(git --git-dir="$(__gitdir)" stash list | sed -n -e 's/:.*//p')"
}
