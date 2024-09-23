function tmux_path() {
  if [ "$USER" == "root" ] ; then
    return
  fi
  tmux setenv TMUXPWD_$(tmux display -p "#I_#P") "$PWD"
  tmux setenv TMUXPATH_$(tmux display -p "#I_#P") "$PATH"
  tmux refresh-client -S
}

function tmux_window_title() {
  ignore="builtin|keyword|not found|^$|tmux"

  function tmux_title {
    title=$1

    # default pane title is the name of the current process (i.e. 'bash')
    if [ -z "$title" ] ; then
      title=$(ps -o comm $$ | tail -1)
    fi

    # remove leading env vars
    title=$(echo $title | perl -pe 's|^[A-Z_]+=\S+||g')

    # remove leading space
    title=$(echo $title | perl -pe 's|^\s+||g')

    # skip
    # - shell builtins/keywords (probably rc scripts, etc)
    # - cases where the type isn't found (setting env variables, etc)
    # - tmux commands, including our functions
    cmd=$(echo $title | perl -pe 's|(.*?)\s.*|\1|')
    cmd_type=$(type $cmd 2> /dev/null | head -1)
    if [[ "$cmd_type" =~ $ignore ]] ; then
      return
    fi

    # attempt to use the alias name if it exists (remove any piping/redirection)
    for a in "${aliases[@]}" ; do
      acmd=$(echo $a | perl -pe "s|.*?='([^'\|]*).*|\1|")
      if [[ -n "$acmd" && "$title" =~ ^$acmd ]] ; then
        aname=$(echo $a | perl -pe 's|alias (.*?)=.*|\1|')
        title=$aname
        break
      fi
    done

    # remove dash args, must be before removing sudo/ssh
    # remove sudo, prefix with # instead
    # remove ssh, prefix with @ instead
    # remove path info
    # remove all but the first part of the command
    title=$(echo $title |
      perl -pe 's|\s-.?\s| |' |
      perl -pe 's|^sudo\s|#|' |
      perl -pe 's|^ssh\s|@|' |
      perl -pe 's|\S*/||g' |
      perl -pe 's|(\S*).*|\1|'
    )

    tmux rename-window -t$TMUX_PANE "$title"
  }

  # set title to the command just before it runs
  trap 'tmux_title "$BASH_COMMAND"' DEBUG

  # set title to the default (current process) before displaying the command prompt
  PROMPT_COMMAND="tmux_path; tmux_title"
}

function tmux_window_title_aliases(){
  # store a reference to all our aliases after we've loaded all rc files,
  # sorted by longest to shortest so that more specific aliases are checked
  # first in the event that the command may match a less specific one
  # first.
  readarray -t aliases <<< "$(
    alias |
    awk '{ print length($0) " " $0; }' |
    sort -r -n |
    cut -d ' ' -f 2- |
    grep alias
  )"
}

if [[ "$TERM" =~ ^tmux ]] ; then
  tmux_window_title
fi
