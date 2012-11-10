" Author:  Eric Van Dewoestine

setlocal spell! spelllang=en_us

augroup gitcommit_cursor
  autocmd! * <buffer>
  autocmd BufWinEnter <buffer> call cursor(1, 1)
augroup END

" vim:ft=vim:fdm=marker
