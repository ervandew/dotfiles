# If not running interactively, don't do anything
[ -z "$PS1" ] && return

[[ -f /etc/profile ]] && . /etc/profile

[[ -f /etc/profile.d/bash-completion ]] && . /etc/profile.d/bash-completion
[[ -f /etc/profile.d/bash-completion.sh ]] && . /etc/profile.d/bash-completion.sh

## Bash settings. {{{
  PROMPT_COMMAND="echo -ne \"\033]0;\${USER}@\${HOSTNAME%%.*}\${showchroot}: \${PWD/\$HOME/~}\007\""

  # bash history settings
  ignore="&:??:clear:exit:k"
  ignore="$ignore:shutdown*:reboot:*systemctl poweroff*:*systemctl reboot*"
  ignore="$ignore:git stash pop*:git stash drop*"
  ignore="$ignore:reload_postgresql*"
  export HISTIGNORE=$ignore
  export HISTCONTROL=ignoreboth
  export HISTSIZE=1000

  # colors {{{
    red='\e[0;31m'
    RED='\e[1;31m'
    green='\e[0;32m'
    GREEN='\e[1;32m'
    yellow='\e[0;33m'
    YELLOW='\e[1;33m'
    blue='\e[0;34m'
    BLUE='\e[1;34m'
    purple='\e[0;35m'
    PURPLE='\e[1;35m'
    cyan='\e[0;36m'
    CYAN='\e[1;36m'
    WHITE='\e[1;37m'
    white='\e[0;37m'
    orange='\e[38;5;214m'
    gray='\e[38;5;239m'
    NONE='\e[0m'
  # }}}
  # Handle sudo -E su -p [<user>]
  WHO=`whoami`
  if [ "$USER" != "$WHO" -o "$USER" == "root" ] ; then
    export USERHOME=`cat /etc/passwd | grep "\<$WHO\>" | cut -d ':' -f6`
    export HISTFILE="$USERHOME/.bash_history.$SUDO_USER"
    export BASH_PS1="${red}\u${blue}@\h${NONE} \w\n# "
  else
    _info() {
      declare -a info

      branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
      if [ -n "$branch" ] ; then
        info+=("git:$branch")
      fi

      if [ -n "$VIRTUAL_ENV" ] ; then
        info+=("ve:$(basename $VIRTUAL_ENV)")
      fi

      if [ -n "$info" ] ; then
        echo -e " $gray(${info[@]})$NONE"
      fi
    }

    PS1_COLOR=${blue}
    if [ "$TERM" == "linux" ] ; then
      PS1_COLOR=${white}
    fi
    export BASH_PS1="$PS1_COLOR\u@\h${NONE} \w\$(_info)\n"$SCREEN_PS1'\$ '
  fi
  export PS1=$BASH_PS1

  # prevent redirect (>) from clobbering an existing file (override with >|)
  # echo "foo" >| file
  set -o noclobber

  # auto correct simple spelling mistakes for cd
  shopt -s cdspell
  # multi line commands stored as single line in history
  shopt -s cmdhist
  # fixes annoying line wrapping issues after resize terminal window.
  shopt -s checkwinsize
  # append to history on close, don't clobber.
  shopt -s histappend

  # complete directories only for the supplied commands.
  # redundent if bash-completion is enabled.
  complete -d cd mkdir rmdir

  # add file completion to psql
  complete -f psql

  # load user bash completions
  if [ -d ~/.bash_completion.d ] ; then
    for bc in `find ~/.bash_completion.d -type f -o -type l -name '*.sh'` ; do
      . $bc
    done
  fi
# }}}

## Aliases {{{
  # aliases to support my bad typing
  alias cd-="cd -"
  alias cd..="cd .."

  # make dirs, then cd into it.
  function mcd() {
    args=$(printf " %q" "$@")
    dir=$(bash -c "mkdir $args && echo \$_")
    if [ -n "$dir" ] ; then
      cd $dir
    fi
  }

  # system aliases
  alias cp="cp -i"
  alias ls="ls --color=auto"
  alias mv="mv -i"
  alias grep="grep --color=auto"
  # pager that uses nvim
  alias less="pager"

  # for dotfiles sync
  function dotfiles() {
    if [[ $PWD =~ .*/dotfiles.* ]] ; then
      stow --ignore=.dotignore --target=$HOME "$@" .
    else
      echo 'error: not a dotfiles directory'
    fi
  }

  # prevent errors when remote shells don't understand my current term.
  alias ssh="TERM='xterm-256color' ssh"

  # always use passive mode
  alias ftp="ftp -p"

  alias sudosu="sudo -E su -p"

  alias envmin="~/bin/envmin ~/.config/envmin/envmin.txt"

  alias whatismyip="dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | sed 's|\"||g'"

  # postgres db shortcuts
  alias lsdb="psql postgres -c '\l'"
  function renamedb(){
    psql postgres -c "alter database $1 rename to $2"
  }
# }}}

## Linux Apps Variables {{{
  export EDITOR=nvim
  export VISUAL=nvim # for some crontab impls
  export PAGER=pager
  export MANPAGER=$PAGER

  # force use of utf 8 (set in ~/.xinitrc as well)
  export LANG="en_US.UTF-8"
  export LC_CTYPE="$LANG"

  # add $HOME/bin to path (set in ~/.xinitrc as well)
  PATH="$HOME/bin:$PATH" ; export PATH

  # color highlighting for grep
  export GREP_COLORS="mt=33" # yellow (colors start at 30)

  # get transparency to work with some terminal apps (mutt)
  export COLORFGBG="default;default"
  export NCURSES_ASSUMED_COLORS="-1;-1"

  export MYSQL_PS1="\u@\h:\p> "

  export PSQLRC=$HOME/.config/psql/psqlrc
# }}}

# load user bash scripts
if [ -d ~/.bashrc.d ] ; then
  for brc in `find ~/.bashrc.d -name '*.sh' | sort` ; do
    . $brc
  done
fi

# load aliases cache after we've applied all rc files
tmux_window_title_aliases

# vim:fdm=marker:nowrap
