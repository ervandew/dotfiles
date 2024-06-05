export PYTHONSTARTUP="$HOME/.pystartup"

if [[ -z "$VIRTUAL_ENV" ]] ; then
  function python-venv {
    if [ $# != 1 ] ; then
      echo "Please supply a venv name."
      exit 1
    fi

    venv="$HOME/.python-venv/$1"

    if [ ! -d "$venv" ] ; then
      read -p "venv '$1' does not exist, create it? (y/n)? "
      if [ "$REPLY" == "y" ] ; then
        versions=$(apropos python | sort | grep "^python[0-9.]* " | cut -d ' ' -f 1)
        readarray -t versions <<< "$versions"
        for index in "${!versions[@]}" ; do
          echo "$index) ${versions[index]}"
        done
        read -p "Please choose a python version: "
        [[ ! "$REPLY" =~ ^[0-9]+$ ]] && echo 'not a number' && exit 1
        [[ $REPLY -gt $index ]] && echo 'invalid index' && exit 1
        python="${versions[REPLY]}"
        $python -m venv "$venv"
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
