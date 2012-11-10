" Author:  Eric Van Dewoestine

imap <buffer> ## <c-r>=<SID>Color('')<cr>
vmap <buffer> ## c<c-r>=<SID>Color(@")<cr><esc>

function! s:Color(color) " {{{
  let cmd = 'zenity --color-selection --show-palette 2> /dev/null'
  let color = a:color
  if color =~? '^#\?[0-9a-f]\+'
    if color[0] != '#'
      let color = '#' . color
    endif
    let cmd .= ' --color=' . color
  endif
  let hex = system(cmd)
  if hex != ''
    let line = getline('.')
    let char = col('.') > 1 ? line[col('.') - 2] : ''
    let start = char == '#' ? 1 : 0
    return hex[start :2] . hex[5:6] . hex[9:10]
  endif
  return a:color
endfunction " }}}

" vim:ft=vim:fdm=marker
