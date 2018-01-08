export PYTHONSTARTUP="$HOME/.pystartup"

# for virtualenv wrapper (only source if we aren't in a virtualenv)
if [ "$USER" != "root" -a -f "/usr/bin/virtualenvwrapper.sh" -a -z "$VIRTUAL_ENV" ] ; then
  export WORKON_HOME=$HOME/.virtualenv
  source /usr/bin/virtualenvwrapper.sh
fi

SCREEN=$(echo "$TERM" | grep "^screen")
if [ -n "$SCREEN" ] ; then
  # hack to support starting screen from virtualenv wrapper's postactivate
  # script, restoring the virtual path which is lost when starting screen.
  #
  # Note: VIRTUAL_PATH and VIRTUAL_ENV_SCREEN are set by:
  #   ~/.virtualenv/postactivate
  if [ -n "$VIRTUAL_PATH" -a "$VIRTUAL_PATH" != "$PATH" ] ; then
    export PATH=$VIRTUAL_PATH
  fi

  # support re-calling postactivate to ensure any additional setup isn't lost
  # when starting screen from postactivate
  if [ -n "$VIRTUAL_ENV_SCREEN" -a -f "$VIRTUAL_ENV/bin/postactivate" ] ; then
    source $VIRTUAL_ENV/bin/postactivate
  fi
fi
