" Author:  Eric Van Dewoestine

" ContextSearch (find element/file under the cursor via <cr>) {{{
nnoremap <silent> <buffer> <cr> :call <SID>ContextSearch()<cr>

try
  function! s:ContextSearch()
    let line = getline('.')
    let col = col('.')

    let paths = []
    let patterns = []

    let possible_path = substitute(line,
      \ "\\(.*[[:space:]\"',(\\[{><]\\|^\\)\\(.*\\%" .
      \ col('.') . "c.\\{-}\\)\\([[:space:]\"',)\\]}<>].*\\|$\\)",
      \ '\2', '')
    if possible_path =~ '\.css$'
      let paths = [
        \ substitute(possible_path, '\.css$', '.scss', ''),
        \ substitute(possible_path, '\.css$', '/index.scss', '')
       \ ]
    elseif possible_path =~ '\.js$' && possible_path !~ '.*/.*'
      let paths = [substitute(possible_path, '\.js', '/index.js', '')]
    elseif possible_path =~ '\.html$'
      let paths = [possible_path]
    else
      let word = expand("<cword>")

      " filter ref
      if line =~ '|' . word . '\>'
        let patterns = [['.py', '\<def\s+' . word . '\>']]

      " url name ref
      elseif line =~ "\\<url\\s*(['\"]" . word . "\\>"
        let patterns = [['.py', '\<def\s+' . word . '\>']]

      " macro ref
      elseif line =~ '{%-\?\s*call\s\+' . word . '\>'
        let patterns = [['.html', '\<macro\s+' . word . '\>']]

      " function or macro ref
      elseif line =~ '{{-\?\s\+' . word . '\>'
        let patterns = [
          \ ['.html', '\<macro\s+' . word . '\>'],
          \ ['.py', '\<def\s+' . word . '\>'],
        \]

      " method ref
      elseif line =~ '\.' . word . '\>\s*('
        let patterns = [['.py', '\<def\s+' . word . '\>']]

      " class reference
      elseif word =~ '^[A-Z][a-z]\+'
        let patterns = [['.py', '\<class\s+' . word . '\>']]
      endif
    endif

    if len(patterns)
      let winnum = winnr()
      " FIXME: updating Ag to support opening a single result in a new window
      " would aleviate the need for this gross code
      for [ext, pattern] in patterns
        silent exec 'Ag! ' . pattern . ' **/*' . ext
        let results = getqflist()
        let num = len(results)
        if num
          break
        endif
      endfor

      if num == 1
        cclose
        exec winnum . 'winc w'
        exec 'new | buffer ' . results[0].bufnr
      else
        echohl WarningMsg | echom 'No result found:' patterns | echohl None
      endif
    elseif len(paths)
      let found = 0
      for path in paths
        silent! let found = ag#search#FindFile(path, 'split')
        if found
          break
        endif
      endfor
      if !found
        echohl WarningMsg | echom 'File not found:' paths | echohl None
      endif
    endif
  endfunction
catch /E127/
endtry " }}}

" vim:fdm=marker
