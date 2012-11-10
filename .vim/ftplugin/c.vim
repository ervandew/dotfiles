" Author:  Eric Van Dewoestine

setlocal errorformat=%f:%l:%c:\ %m,%f:%l:\ %m,%-G%.%#

nnoremap <silent> <buffer> <cr> :CSearchContext<cr>

" vim:ft=vim:fdm=marker
