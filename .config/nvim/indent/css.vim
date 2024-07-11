" Css indent file using IndentAnything.

let b:did_indent = 1

runtime indent/indentanything.vim

setlocal indentexpr=GetCssIndent(v:lnum)
setlocal indentkeys=0{,0},!^F,o,O

function! GetCssIndent(lnum) " {{{
  let adj = 0
  let prevline = prevnonblank(a:lnum - 1)

  " handle case where previous line is a multi-line comment (/* */) on one
  " line, which IndentAnything doesn't handle properly.
  if getline(prevline) =~ '^\s\+/\*.\{-}\*/\s*$'
    let adj = indent(prevline)
  endif

  return IndentAnything() + adj
endfunction " }}}

function! CssIndentAnythingSettings() " {{{
  " Syntax name REs for comments and strings.
  let b:commentRE      = 'cssComment'
  let b:lineCommentRE  = 'cssComment'
  let b:blockCommentRE = 'cssComment'
  let b:stringRE            = 'cssStringQ\(Q\)\?'

  " Setup for C-style comment indentation.
  let b:blockCommentStartRE  = '/\*'
  let b:blockCommentMiddleRE = '\*'
  let b:blockCommentEndRE    = '\*/'
  let b:blockCommentMiddleExtra = 1

  " Indent another level for each non-closed paren/'(' and brace/'{' on the
  " previous line.
  let b:indentTrios = [
        \ [ '{', '', '}' ]
  \ ]
endfunction " }}}

call CssIndentAnythingSettings()

" vim:fdm=marker
