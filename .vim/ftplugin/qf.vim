" Author:  Eric Van Dewoestine
"
" Provides some additional mappings when working with vim's quickfix, allowing
" removal of entries or opening of entries in a split window.

xnoremap <buffer> <silent> d :call <SID>Delete()<cr>
nnoremap <buffer> <silent> dd :call <SID>Delete()<cr>
nnoremap <buffer> <silent> D :call <SID>Delete()<cr>
nnoremap <buffer> <silent> e <cr>:cclose<cr>
nnoremap <buffer> <silent> s :call <SID>Split(1)<cr>
nnoremap <buffer> <silent> S :call <SID>Split(0)<cr>

if !exists('*s:Delete')
function! s:Delete(...) range " {{{
  let lnum = line('.')
  let cnum = col('.')

  if exists('a:firstline')
    let start = a:firstline
    let end = a:lastline
  else
    let start = lnum
    let end = lnum
  endif

  let qf_props = getqflist({'all' : 1})
  let qf = qf_props['items']
  call remove(qf, start - 1, end - 1)
  call setqflist([], 'r', qf_props)
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
