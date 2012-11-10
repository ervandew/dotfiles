" Author:  Eric Van Dewoestine

augroup xml_encoding
  autocmd! BufWinEnter <buffer>
  autocmd BufWinEnter <buffer> call <SID>XmlEncoding()
augroup END

function! s:XmlEncoding () " {{{
  if !&ro
    let regex = '^\s*<?xml.*encoding="\(.\{-}\)"?>\s*$'
    if getline(1) =~ regex
      let encoding = substitute(getline(1), regex, '\1', '')
      if &fileencoding != encoding
        exec 'set fileencoding=' . encoding
      endif
      if &encoding != encoding
        exec 'set encoding=' . encoding
      endif
    endif
  endif
endfunction " }}}

" vim:ft=vim:fdm=marker
