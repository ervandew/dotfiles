" Author:  Eric Van Dewoestine

nnoremap <buffer> <cr> :call <SID>ContextSearch()<cr>

try
  function! s:ContextSearch()
    let line = getline('.')
    let col = col('.')

    let call_pattern = '.*{%-\?\s*call\s\+\(\<\w*\%' . col . 'c\w*\>\).*'
    if line =~ call_pattern
      let word = substitute(line, call_pattern, '\1', '')
      let winnum = winnr()
      " FIXME: updating Ag to support opening a single result in a new window
      " would aleviate the need for this gross code
      exec 'Ag! \<macro\s+' . word . ' **/*.html'

      let results = getqflist()
      let num = len(results)
      if num
        if num == 1
          cclose
          exec winnum . 'winc w'
          exec 'new | buffer ' . results[0].bufnr
        endif
      endif
    else
      let file = eclim#util#GrabUri()
      if file =~ '\.css$'
        let file = substitute(file, '\.css$', '.scss', '')
        call eclim#common#locate#LocateFile('split', file)
      else
        call eclim#common#locate#LocateFile('split', '<cursor>')
      endif
    endif
  endfunction
catch /E127/
endtry

" vim:ft=vim:fdm=marker
