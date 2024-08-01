if $(which fzf &> /dev/null) ; then
  eval "$(fzf --bash)"

  # use tab/s-tab to scroll through results
  # add preview w/ ctrl-d/u for scrolling
  export FZF_DEFAULT_OPTS="
    --bind=tab:down,shift-tab:up,ctrl-d:preview-page-down,ctrl-u:preview-page-up
    --preview 'bat --color=always --theme=base16 {}'
  "

  # let rg handle ignoring files (.gitignore, etc)
  export FZF_DEFAULT_COMMAND="rg --files --hidden --glob '!.git'"
  # ditto for command line path completion
  _fzf_compgen_path() {
    rg --files --hidden --glob '!.git' "$1"
  }
fi
