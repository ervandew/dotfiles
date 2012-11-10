" Author:  Eric Van Dewoestine

if bufname('%') !~ '^\(command-line\|\[Command Line\]\)$'
  nnoremap <silent> <buffer> <cr> :Lookup<cr>
endif

" vim:ft=vim:fdm=marker
