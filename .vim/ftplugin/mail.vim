" Author:  Eric Van Dewoestine

setlocal foldmethod=expr
setlocal foldexpr=FoldMail()

if !&readonly
  setlocal textwidth=70
  setlocal spell spelllang=en
else
  setlocal nospell
endif

augroup mail
  autocmd!
  autocmd VimEnter * :call <SID>InitMail()
augroup END

nmap <silent> <buffer> <cr> :call <SID>FollowLink()<cr>

function! FoldMail() " {{{
  " headers
  if s:IsHeaderLine(v:lnum)
    return 1
  endif

  " reply quotes
  return strlen(substitute(substitute(getline(v:lnum),'\\s','','g'),'[^>].*','',''))
endfunction " }}}

function! s:InitMail() " {{{
  if &ft != 'mail'
    return
  endif

  " view
  if &readonly
    " jump to the line after the second blank line when viewing mail.
    call cursor(1, 1)
    call search('^$')
    call search('^$')
    call cursor(line('.') + 1, 0)

  " compose
  elseif line('$') != 1
    " when composing mail via gmail + vimperator, remove leading and trailing
    " blank lines.
    while line('$') != 1 && getline(1) =~ '^\s*$'
      1,1delete _
    endwhile
    while line('$') != 1 && getline('$') =~ '^\s*$'
      $,$delete _
    endwhile

    " jump to the first blank line when composing mail
    call cursor(1, 1)
    call search('^$')

    " if there are 2 more blank lines (gmail), then delete one to mimic
    " initial content when using mutt.
    if getline(line('.') + 1) =~ '^\s*$' && getline(line('.') + 2) =~ '^\s*$'
      .,.delete _
    endif
  endif
endfunction " }}}

function! s:IsHeaderLine(lnum) " {{{
  let last_header = exists('b:mail_headers_end') ? b:mail_headers_end : 0

  let header = '^[A-Z][a-zA-Z]*\(-[A-Z][a-zA-Z]*\)*:\s'
  let header_cont = '^\t\S'
  if getline(a:lnum) =~ header
    if !last_header || a:lnum == last_header + 1
      let b:mail_headers_end = a:lnum
      return 1
    elseif a:lnum <= last_header
      return 1
    endif
  endif

  if getline(a:lnum) =~ header_cont
    let line = a:lnum
    while line > 0 && getline(line) =~ header_cont
      let line -= 1
      if getline(line) =~ header
        if !last_header || a:lnum == last_header + 1
          let b:mail_headers_end = a:lnum
          return 1
        endif
      endif
    endwhile
  endif

  if a:lnum == 1 && getline(a:lnum) =~ '^-'
    return 1
  endif

  if a:lnum > 1 && getline(a:lnum) =~ '^$'
    return s:IsHeaderLine(a:lnum - 1) && s:IsHeaderLine(a:lnum + 1)
  endif

  return 0
endfunction " }}}

function! s:FollowLink () " {{{
  let line = getline('.')
  let cnum = col('.')
  let pattern1 = '.*\w*\%' . cnum . 'c\w*\s*\(\[\d\+\]\).*'
  let pattern2 = '.*\(\[\d\+\]\)\w*\%' . cnum . 'c\w*.*'
  let pattern3 = '.*\(\%' . cnum . 'c\[\d\+\]\|' .
    \ '\[\d*\%' . cnum . 'c\d\+\]\|' .
    \ '\[\d\+\%' . cnum . 'c\d*\]\).*'
  let pattern4 = '.\{-}\%' . cnum . 'c.\{-}\(\[\d\+\]\).*'

  let link = ''
  if line =~ pattern1
    let link = substitute(line, pattern1, '\1', '')
  elseif line =~ pattern2
    let link = substitute(line, pattern2, '\1', '')
  elseif line =~ pattern3
    let link = substitute(line, pattern3, '\1', '')
  elseif line =~ pattern4
    let link = substitute(line, pattern4, '\1', '')
  endif

  if link != ''
    let pos = getpos('.')
    normal m`m'
    call cursor('$', 1)
    let found = search(escape(link, '[]') . '\s\+[a-z]\+://', 'bcW')
    if !found
      " try using the elinks dump format
      let link = link[1:-2]
      let found = search('^\s*' . link . '\.\s\+[a-z]\+://', 'bcW')
    endif

    if found
      call search('[a-z]\+://')
    else
      call setpos('.', pos)
    endif
  else
    let link = eclim#util#GrabUri()
    if link =~ '^[a-z]\+://'
      call eclim#web#OpenUrl(link)
    endif
  endif
endfunction " }}}

" vim:ft=vim:fdm=marker
