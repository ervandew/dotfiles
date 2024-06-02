" Author:  Eric Van Dewoestine

command! -buffer Browser :silent exec '!rifle "' . expand('%:p') . '"' | redraw!

" vim:ft=vim:fdm=marker
