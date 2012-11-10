" Author: Eric Van Dewoestine

if exists('g:SuperTabCompletionContexts')
  let b:SuperTabCompletionContexts =
    \ ['ClojureContext'] + g:SuperTabCompletionContexts

  function! ClojureContext()
    let curline = getline('.')
    let cnum = col('.')
    let synname = synIDattr(synID(line('.'), cnum - 1, 1), 'name')
    if curline =~ '(\S\+\%' . cnum . 'c' && synname !~ '\(String\|Comment\)'
      return "\<c-x>\<c-o>"
    endif
  endfunction
endif
