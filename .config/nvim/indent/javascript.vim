" Javascript indent file using IndentAnything.
" Based on initial version developed by:
"   Tye Z. <zdro@yahoo.com>
" The version accounts for a couple edge cases not handled in the ideal
" manner by IndentAnything.

let b:did_indent = 1

runtime indent/indentanything.vim

setlocal indentexpr=GetJavascriptIndent(v:lnum)
setlocal indentkeys+=0),0},),;

function! GetJavascriptIndent(lnum) " {{{
  let line = getline(a:lnum)
  let prevlnum = prevnonblank(a:lnum - 1)
  let prevline = getline(prevlnum)
  let pattern_heads = '\(' . join(map(copy(b:indentTrios), 'v:val[0]'), '\|') . '\)'

  for trio in b:indentTrios
    " if the current line starts with any of the ending trios, then set the
    " current line indent to the same indent as the line starting that trio.
    if line =~ '^\s*' . trio[2]
      let col = col('.')
      call cursor(0, col('$'))

      let matchstart = 0
      while search(')\|}\|\]', 'bcW', line('.')) && col('.') != 1
        let end = line[col('.') - 1]
        let start = ''
        for trio in b:indentTrios
          if trio[2] == end
            let start = trio[0]
            break
          endif
        endfor
        let matchstart = searchpair(start, '', end, 'bnW', 'InCommentOrString()')
        if matchstart > 0 && matchstart < line('.')
          break
        endif
        call cursor(0, col('.') - 1)
      endwhile

      call cursor(0, col)

      if matchstart > 0
        return indent(matchstart)
      endif
    endif
  endfor

  for trio in b:indentTrios
    " if the previous line starts with any of the ending trios, then indent
    " one level to compensate for our adjustment above.
    if prevline =~ '^\s*' . trio[2] && prevline !~ pattern_heads . '$'
      let col = col('.')
      call cursor(a:lnum - 1, 1)
      let matchstart = searchpair(trio[0], '', trio[2], 'bnW', 'InCommentOrString()')
      call cursor(0, col)

      " if the matching opener is on it's own line, then use the previous line
      " indent.
      if matchstart > 0 && getline(matchstart) =~ '^\s*' . trio[0]
        return indent(prevnonblank(matchstart - 1))
      endif
      return indent(prevlnum)
    endif
  endfor

  return IndentAnything()
endfunction " }}}

function! JavascriptIndentAnythingSettings() " {{{
  " Syntax name REs for comments and strings.
  let b:commentRE      = 'javaScript\(Line\)\?Comment'
  let b:lineCommentRE  = 'javaScriptLineComment'
  let b:blockCommentRE = 'javaScriptComment'
  let b:stringRE            = 'javaScript\(String\(S\|D\)\|RegexpString\|Special\)'
  let b:singleQuoteStringRE = 'javaScriptStringS'
  let b:doubleQuoteStringRE = 'javaScriptStringD'

  " Setup for C-style comment indentation.
  let b:blockCommentStartRE  = '/\*'
  let b:blockCommentMiddleRE = '\*'
  let b:blockCommentEndRE    = '\*/'
  let b:blockCommentMiddleExtra = 1

  " Indent another level for each non-closed paren/'(' and brace/'{' on the
  " previous line.
  let b:indentTrios = [
        \ [ '(', '', ')' ],
        \ [ '\[', '', '\]' ],
        \ [ '{', '\(default:\|case.*:\)', '}' ]
  \]

  " Line continuations.  Lines that are continued on the next line are
  " if/for/while statements that are NOT followed by a '{' block and operators
  " at the end of a line.
  let b:lineContList = [
    \ { 'pattern' : '^\s*\(if\|for\|while\)\s*(.*)\s*\(\(//.*\)\|/\*.*\*/\s*\)\?\_$\(\_s*{\)\@!' },
    \ { 'pattern' : '^\s*else' . '\s*\(\(//.*\)\|/\*.*\*/\s*\)\?\_$\(\_s*{\)\@!' },
    \ { 'pattern' : '\(+\|=\|+=\|-=\)\s*\(\(//.*\)\|/\*.*\*/\s*\)\?$' }
  \]

  " If a continued line and its continuation can have line-comments between
  " them, then this should be true.  For example,
  "
  "       if (x)
  "           // comment here
  "           statement
  "
  let b:contTraversesLineComments = 1
endfunction " }}}

call JavascriptIndentAnythingSettings()

" vim:fdm=marker
