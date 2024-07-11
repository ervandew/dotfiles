" Html indent file using IndentAnything.

runtime indent/indentanything.vim
runtime indent/javascript.vim
runtime indent/css.vim

setlocal indentexpr=GetHtmlIndent(v:lnum)
setlocal indentkeys+=>,},0),0},),;,0{,!^F,o,O

let g:HtmlUnclosedTags = ['br', 'img', 'input']

function! GetHtmlIndent(lnum) " {{{
  let line = line('.')
  let col = line('.')

  let adj = 0

  let scriptstart = search('<script\>', 'bcW')
  if scriptstart > 0
    let scriptstart = search('>', 'cW', scriptstart)
    let scriptend = search('</script\s*>', 'cW')
  endif
  call cursor(line, col)

  let stylestart = search('<style\>', 'bcW')
  if stylestart > 0
    let stylestart = search('>', 'cW', stylestart)
    let styleend = search('</style\s*>', 'cW')
  endif
  call cursor(line, col)

  " Inside <script> tags... let javascript indent file do the work.
  let line = getline(scriptstart)
  let js_type = "type\\s*=\\s*['\"]\\(text\\|application\\)/\\(java\\|ecma\\)script['\"]"
  if scriptstart > 0 && scriptstart < a:lnum &&
        \ (scriptend == 0 || (scriptend > scriptstart && a:lnum < scriptend)) &&
        \ (line !~ 'type\s*=' || line =~ js_type)
    call JavascriptIndentAnythingSettings()
    if a:lnum == scriptstart + 1
      let adj = &sw
    endif
    return GetJavascriptIndent(a:lnum) + adj

  " Inside <style> tags... let css indent file do the work.
  elseif stylestart > 0 && stylestart < a:lnum &&
        \ (styleend == 0 || (styleend > stylestart && a:lnum < styleend))
    call CssIndentAnythingSettings()
    if a:lnum == stylestart + 1
      let adj = &sw
    endif
    return GetCssIndent(a:lnum) + adj

  " Indenting html code, do our work.
  else
    let l:Settings = exists('b:indent_settings') ?
      \ function(b:indent_settings) : function('HtmlIndentAnythingSettings')
    call l:Settings()
    let adj = s:HtmlIndentAttributeWrap(a:lnum) * &sw

    let prevlnum = prevnonblank(a:lnum - 1)
    let prevline = getline(prevlnum)

    " handle case where previous line is a multi-line comment (<!-- -->) on one
    " line, which IndentAnything doesn't handle properly.
    if prevline =~ '^\s\+<!--.\{-}-->'
      let adj = indent(prevlnum)
    endif

    " handle non-parent tags without '/>'
    " NOTE: the '?' in this regex is to combat issues with php
    let noindent = exists('b:HtmlUnclosedTags') ?
      \ b:HtmlUnclosedTags : g:HtmlUnclosedTags
    let noindent_pattern = '<\(' . join(noindent, '\|') . '\)[^/?]\{-}>'
    if prevline =~? noindent_pattern
      let line = tolower(prevline)
      let occurrences = 0
      while line =~ noindent_pattern
        let occurrences += 1
        let line = substitute(line, noindent_pattern, '', '')
      endwhile
      let adj = 0 - (&sw * occurrences)
    endif
  endif
  return IndentAnything() + adj
endfunction " }}}

function! HtmlIndentAnythingSettings() " {{{
  " Syntax name REs for comments and strings.
  let b:blockCommentRE = 'htmlComment'
  let b:commentRE      = b:blockCommentRE
  let b:stringRE       = 'htmlString'
  let b:singleQuoteStringRE = b:stringRE
  let b:doubleQuoteStringRE = b:stringRE

  " Overwrites option for other filetypes that have html indenting (eg. php)
  "setlocal comments=sr:<!--,m:-,e:-->
  "let b:blockCommentStartRE  = '<!--'
  "let b:blockCommentMiddleRE = '-'
  "let b:blockCommentEndRE    = '-->'
  "let b:blockCommentMiddleExtra = 2

  " Indent another level for each non-closed element tag.
  let b:indentTrios = [
      \ [ '<\w', '', '\(/>\|</\)' ],
    \ ]

  "let b:lineContList = [
  "    \ {'pattern' : '^<!DOCTYPE.*[^>]\s*$' },
  "  \ ]
endfunction " }}}

function! <SID>HtmlIndentAttributeWrap(lnum) " {{{
  " Function which indents line continued attributes an extra level for
  " readability.
  let line = line('.')
  let col = col('.')
  let adj = 0
  try
    " mover cursor to start of line to avoid matching start tag on first line
    " of nested content.
    call cursor(line, 1)
    let open = search('<\w\|<!DOCTYPE', 'bW')
    if open > 0
      let close = search('>', 'cW')
      if open != close
        " continuation line
        if close == 0 || close >= a:lnum
          " first continuation line
          if a:lnum == open + 1
            return 1
          endif
          " additional continuation lines
          return 0
        endif

        " line after last continuation line
        if close != 0 && a:lnum == close + 1
          " inner content
          return -1
        endif
      endif
    endif
  finally
    call cursor(line, col)
  endtry
endfunction " }}}

" vim:fdm=marker
