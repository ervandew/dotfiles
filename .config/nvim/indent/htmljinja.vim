" Jinja Html template indent file using IndentAnything.

runtime! indent/html.vim

let elements = [
  \ ['block', 'endblock'],
  \ ['call', 'endcall'],
  \ ['filter', 'endfilter'],
  \ ['for', 'endfor'],
  \ ['if', 'elif', 'else', 'endif'],
  \ ['macro', 'endmacro'],
\ ]

let s:open_elements = ''
let s:mid_elements = ''
for element in elements
  if len(s:open_elements) > 0
    let s:open_elements .= '\|'
  endif
  let s:open_elements .= element[0]

  for tag in element[1:-2]
    if len(s:mid_elements) > 0
      let s:mid_elements .= '\|'
    endif
    let s:mid_elements .= tag
  endfor

  exec 'setlocal indentkeys+==end' . element[0]
endfor

function! HtmlJinjaIndentAnythingSettings() " {{{
  if exists('*HtmlSettings')
    call HtmlIndentAnythingSettings()
  endif

  let b:indentTrios = [
      \ [ '<\w', '', '\(/>\|</\)' ],
      \ [ '{%-\?\s*\(' . s:open_elements . '\)\(\s\+.\{-}\)\?-\?%}',
        \ '{%-\?\s*\(' . s:mid_elements . '\)\(\s\+.\{-}\)\?-\?%}',
        \ '{%-\?\s*end\w\+\s*-\?%}' ],
    \ ]
endfunction " }}}

let b:indent_settings = 'HtmlJinjaIndentAnythingSettings'

" vim:fdm=marker
