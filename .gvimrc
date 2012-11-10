" Author: Eric Van Dewoestine

" vim options {{{
  set guioptions=a
  set noerrorbells
  set visualbell t_vb= " turn off system beeps and visual flash
" }}}

" Mappings {{{

  if exists('g:vimplugin_running')
    nmap <silent> <c-f5> :call eclim#vimplugin#FeedKeys('Alt+Shift+X,J')<cr>
    nmap <silent> <c-f6> :call eclim#vimplugin#FeedKeys('Ctrl+F6')<cr>
    nmap <silent> <c-f7> :call eclim#vimplugin#FeedKeys('Ctrl+F7')<cr>
    nmap <silent> <c-f> :call eclim#vimplugin#FeedKeys('Ctrl+Shift+R')<cr>
  endif

" }}}

" vim:ft=vim:fdm=marker
