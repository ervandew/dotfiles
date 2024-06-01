" Author:  Eric Van Dewoestine

setlocal omnifunc=pythoncomplete#Complete

" Note: both __pycache__ patterns are required for vim command and *Relative
" completion, and the order of these patterns seems to matter
set wildignore+=*.pyc,*.pyo,*/__pycache__,*/__pycache__/*

let python_highlight_all = 1

" python_match.vim
nmap <buffer> {{ [%
nmap <buffer> }} ]%

nnoremap <silent> <buffer> <cr> :DjangoContextOpen<cr>

command! -buffer -nargs=0 -range=% FormatStack :call <SID>FormatStack(<line1>, <line2>)

function! s:FormatStack(line1, line2) " {{{
  let pos = getpos('.')
  let [line1, line2] = a:line1 < a:line2 ? [a:line1, a:line2] : [a:line2, a:line1]
  exec line1 . ',' . line2 . 's/\([^\n]\)\s\+\(File ".\{-}",\)/\1\r    \2/g'
  let line2 = line('.')
  exec line1 . ',' . line2 . 's/\(File ".\{-}", line \d\+, in [^ ]\+\)\s\+/\1\r        /'
  call setpos('.', pos)
endfunction " }}}

" vim:ft=vim:fdm=marker
