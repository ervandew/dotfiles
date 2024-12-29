export PYTHONSTARTUP=$HOME/.config/python/startup
export PYTHON_HISTORY=$HOME/.local/share/python/history
export PYENV_ROOT=$HOME/.config/python/venv
export IPYTHONDIR=$HOME/.config/ipython

if [[ -z "$VIRTUAL_ENV" ]] ; then
  function python-venv {
    if [ $# != 1 ] ; then
      echo "Please supply a venv name."
      exit 1
    fi

    venv="$PYENV_ROOT/$1"

    if [ ! -d "$venv" ] ; then
      read -p "venv '$1' does not exist, create it? (y/n)? "
      if [ "$REPLY" == "y" ] ; then
        versions=$(uv python list --only-installed | grep -v -- "->" | sed 's|.*\s||')
        readarray -t versions <<< "$versions"
        for index in "${!versions[@]}" ; do
          echo "$index) $(basename ${versions[index]})"
        done
        read -p "Please choose a python version: "
        [[ ! "$REPLY" =~ ^[0-9]+$ ]] && echo 'not a number' && exit 1
        [[ $REPLY -gt $index ]] && echo 'invalid index' && exit 1
        python="${versions[REPLY]}"
        $python -m venv "$venv"
      fi
    elif [ ! -f $(readlink -f "$venv/bin/python") ] ; then
      read -p "venv '$1' python binary is no longer valid. delete this venv? (y/n)? "
      if [ "$REPLY" == "y" ] ; then
        rm -r "$venv"
        python-venv "$1"
        return $?
      else
        return 0
      fi
    fi

    if [ -d "$venv" ] ; then
      source "$venv/bin/activate"

      if [[ ! "$TERM" =~ ^tmux ]] ; then
        name=$(basename $VIRTUAL_ENV)
        tmux -L "$name" new-session -s "$name" -A
        deactivate
      fi
    fi
  }
fi
