if $(which fzf &> /dev/null) ; then
  eval "$(fzf --bash)"

  # let rg handle ignoring files (.gitignore, etc)
  export FZF_DEFAULT_COMMAND="rg --files"
  # ditto for command line path completion
  _fzf_compgen_path() {
    rg --files "$1"
  }
fi
