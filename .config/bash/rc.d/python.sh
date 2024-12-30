export PYTHONSTARTUP=$HOME/.config/python/startup
export PYTHON_HISTORY=$HOME/.local/share/python/history
export PYENV_ROOT=$HOME/.config/python/venv
export IPYTHONDIR=$HOME/.config/ipython

if [[ -z "$VIRTUAL_ENV" ]] ; then
  function python-venv {
    if [ $# != 1 ] ; then
      echo "Please supply a venv name."
      return 1
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

  function python-uwsgi {
    if [ $# != 1 ] ; then
      echo "Please supply a venv name."
      return 1
    fi

    venv=$1
    cwd=$PWD

    packages="
    devtools
    uwsgi
    uwsgi-plugin-python
    "
    for package in $packages ; do
      if ! pacman -Qi $package &> /dev/null ; then
        echo "install $package"
        sudo pacman -S $package
      fi
    done

    sources=$HOME/arch/pkgbuild/uwsgi-plugin-python/sources
    mkdir -p $sources
    cd $sources

    pkgctl repo clone --protocol=https uwsgi

    cd uwsgi
    git fetch
    git merge origin

    rm uwsgi-*.tar.gz &> /dev/null
    rm -r src &> /dev/null

    echo "Download package source files..."
    makepkg -od

    src_dir=$(find src -maxdepth 1 -name "uwsgi*" -type d)

    PYTHON=$HOME/.config/python/venv/$venv/bin/python \
      uwsgi --build-plugin "$src_dir/plugins/python python"

    echo "Install plugin and restart uwsgi..."
    sudo chown root:root python_plugin.so
    sudo mv python_plugin.so /usr/lib/uwsgi/

    sudo systemctl stop uwsgi@emperor
    sudo systemctl start uwsgi@emperor

    cd $cwd
  }
fi
