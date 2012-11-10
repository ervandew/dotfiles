" Author: Eric Van Dewoestine

compiler rst2html

if getline('$') =~ '^\.\. compiler:\w\+$'
  let compiler = substitute(getline('$'), '^\.\. compiler:\(\w\+\)$', '\1', '')
  exec 'compiler ' . compiler
endif
