" Author:  Eric Van Dewoestine
"
" Provides some additional mappings when working with vim's quickfix, allowing
" removal of entries or opening of entries in a split window.

nnoremap <buffer> <silent> dd :call <SID>Delete()<cr>
nnoremap <buffer> <silent> D :call <SID>Delete()<cr>
nnoremap <buffer> <silent> e <cr>:cclose<cr>
nnoremap <buffer> <silent> s :call <SID>Split(1)<cr>
nnoremap <buffer> <silent> S :call <SID>Split(0)<cr>

if !exists('*s:Delete')
function! s:Delete() " {{{
  let lnum = line('.')
  let cnum = col('.')
  let qf = getqflist()
  call remove(qf, lnum - 1)
  call setqflist(qf, 'r')
  call cursor(lnum, cnum)
endfunction " }}}
endif

if !exists('*s:Split')
function! s:Split(close) " {{{
  let list = getloclist(0)
  if len(list) == 0
    let list = getqflist()
  endif

  let bufnum = bufnr('%')
  let saved = &splitbelow
  set splitbelow

  " Doesn't work so well w/ ':botright copen' and vertical splits
  "exec "normal \<c-w>\<cr>"
  let entry = list[line('.') - 1].bufnr
  if index(tabpagebuflist(), entry) == -1
    winc p
    exec 'new | buffer ' . entry
    exec bufwinnr(bufnum) . 'winc w'
  endif
  exec "normal! \<cr>"

  let &splitbelow = saved

  if a:close
    exec 'bd ' . bufnum
  endif
endfunction " }}}
endif

" vim:ft=vim:fdm=marker
