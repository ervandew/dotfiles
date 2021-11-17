# If not running interactively, don't do anything
[ -z "$PS1" ] && return

[[ -f /etc/profile ]] && . /etc/profile

[[ -f /etc/profile.d/bash-completion ]] && . /etc/profile.d/bash-completion
[[ -f /etc/profile.d/bash-completion.sh ]] && . /etc/profile.d/bash-completion.sh

## Bash settings. {{{
  # bash history settings
  ignore="&:??:clear:exit:k"
  ignore="$ignore:shutdown*:reboot:*systemctl poweroff*:*systemctl reboot*"
  ignore="$ignore:git stash pop*:git stash drop*"
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
    _virtualenv_name() {
      if [ -n "$VIRTUAL_ENV" ] ; then
        echo -e " $gray(ve:$(basename $VIRTUAL_ENV))$NONE"
      fi
    }

    # screen required content to auto set the shell title base on last command typed
    export SCREEN_PS1='\[\033k\033\\\]'

    PS1_COLOR=${blue}
    if [ "$TERM" == "linux" ] ; then
      PS1_COLOR=${white}
    fi
    export BASH_PS1="$PS1_COLOR\u@\h${NONE} \w\$(_virtualenv_name)\n"$SCREEN_PS1'\$ '
  fi
  export PS1=$BASH_PS1

  function set_multiplexer_path() {
    if [ "$USER" == "root" ] ; then
      return
    fi

    # force screen cwd to follow shell cwd
    if [ -z "$TMUX" ] ; then
      screen -X chdir "`pwd`" 2> /dev/null
    else
      tmux setenv TMUXPWD_$(tmux display -p "#I_#P") "$PWD"
      tmux setenv TMUXPATH_$(tmux display -p "#I_#P") "$PATH"
      tmux refresh-client -S
    fi
  }

  # set terminal title
  case $TERM in
    *xterm|rxvt*)
      PROMPT_COMMAND="echo -ne \"\033]0;\${USER}@\${HOSTNAME%%.*}\${showchroot}: \${PWD/\$HOME/~}\007\""
      ;;
    screen*)
      PROMPT_COMMAND="set_multiplexer_path"
      ;;
  esac

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

  # set backspace to erase
  #stty erase ^?

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
    # run in a subshell to prevent preexec from polluting $_
    args=$(printf " %q" "$@")
    dir=$(bash -c "mkdir $args && echo \$_")
    if [ -n "$dir" ] ; then
      cd $dir
    fi
  }

  # system aliases
  alias cp="cp -i"
  alias ls="ls --color"
  alias mv="mv -i"
  alias grep="grep --colour=auto"

  # prevent errors when remote shells don't understand my current term.
  alias ssh="TERM='rxvt' ssh"

  # coerce screen to redraw on exit
  if [ $TERM != "xterm" -a $TERM != "rxvt" ] ; then
    alias screen="TERM='rxvt' screen"
  fi

  # aliases for vim
  alias vi="vim"
  alias :e="vim"
  alias :q="exit"
  alias less="vimpager"
  alias vimdiff="vim -d"
  alias vimmin="vim -u NONE --cmd 'set nocp | sy on | filetype plugin indent on'"
  alias vimlarge="vim -u NONE --cmd 'set noswf nowrap undolevels=-1' --cmd 'autocmd BufReadPre * setlocal bt=nowrite'"

  # if not in X, tell vim not to attempt connection w/ X server
  if [ "$DISPLAY" == "" ] ; then
    alias vim="vim -X"
  fi

  # always use passive mode
  alias ftp="ftp -p"

  alias reboot="~/bin/shutdown -r"
  alias suspend="~/bin/shutdown -s"
  alias sudosu="sudo -E su -p"

  alias envmin="~/bin/envmin ~/.envmin/envmin.txt"

  #alias whatismyip="wget -qnv -O - http://checkip.dyndns.org/ | grep -oP '\d+\.\d+\.\d+\.\d+'"
  alias whatismyip="dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | sed 's|\"||g'"

  alias irssi="urxvt -name irssi -title irssi -e irssi &"

  # postgres db shortcuts
  alias lsdb="psql postgres -c '\l'"
  function renamedb(){
    psql postgres -c "alter database $1 rename to $2"
  }
# }}}

## Linux Apps Variables {{{
  export EDITOR=vim
  export VISUAL=vim # for some crontab impls
  export PAGER=vimpager

  # force urxvt to use utf 8 (set in ~/.xinitrc as well)
  export LANG="en_US.UTF-8"
  export LC_CTYPE="$LANG"

  # add $HOME/bin to path (set in ~/.xinitrc as well)
  PATH="$HOME/bin:$PATH" ; export PATH

  # color highlighting for grep
  export GREP_COLOR=33 # yellow (colors start at 30)

  # set vim as the man pager
  export MANPAGER=$PAGER

  # set location of cvs password file
  export CVS_PASSFILE=~/.cvspass
  # set edititor to use for commit comments
  export CVSEDITOR=vim

  # get transparency to work with some terminal apps (mutt)
  export COLORFGBG="default;default"
  export NCURSES_ASSUMED_COLORS="-1;-1"

  # disable virtualenv prompt
  export VIRTUAL_ENV_DISABLE_PROMPT=1
# }}}

# load user bash scripts
if [ -d ~/.bashrc.d ] ; then
  for brc in `find ~/.bashrc.d -name '*.sh' | sort` ; do
    . $brc
  done
fi

if type preexec_install &> /dev/null ; then
  preexec_install
fi

# vim:fdm=marker:nowrap
