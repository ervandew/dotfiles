" Author:  Eric Van Dewoestine

setlocal omnifunc=phpcomplete#CompletePHP
setlocal formatoptions+=croql
setlocal comments=sr:/**,m:*,e:**/
setlocal commentstring=/**%s

" prevent vim shipped php.vim from setting a broken match_words list.
if exists('loaded_matchit')
  unlet loaded_matchit
endif
let b:match_words =
  \ '<?php:?>,' .
  \ '\<if\>:\<elseif\>:\<else\>,' .
  \ '\<do\>:\<while\>,' .
  \ '\<function\>:\<return\>,' .
  \ '<:>,' .
  \ '<\@<=[ou]l\>[^>]*\%(>\|$\):<\@<=li\>:<\@<=/[ou]l>,' .
  \ '<\@<=dl\>[^>]*\%(>\|$\):<\@<=d[td]\>:<\ @<=/dl>,' .
  \ '<\@<=\([^?/][^ \t>]*\)[^>]*\%(>\|$\):<\@<=/\1>'

nnoremap <silent> <buffer> <cr> :PhpSearchContext<cr>

" vim:ft=vim:fdm=marker
