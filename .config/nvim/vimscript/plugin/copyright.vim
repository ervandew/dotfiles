" Author: Eric Van Dewoestine
"
" Description:
"   Plugin used to maintain proper copyright years of files.  Upon saving a
"   file this plugin will check if the file has a copyright declaration and if
"   the most recent year in that copy right matches the current year.  If not,
"   then you are prompted as to whether you would like this plugin to update
"   the copyright accordingly.
"
" License: {{{
"   Copyright (c) 2009 - 2013, Eric Van Dewoestine
"   All rights reserved.
"
"   Redistribution and use of this software in source and binary forms, with
"   or without modification, are permitted provided that the following
"   conditions are met:
"
"   * Redistributions of source code must retain the above
"     copyright notice, this list of conditions and the
"     following disclaimer.
"
"   * Redistributions in binary form must reproduce the above
"     copyright notice, this list of conditions and the
"     following disclaimer in the documentation and/or other
"     materials provided with the distribution.
"
"   * Neither the name of Eric Van Dewoestine nor the names of its
"     contributors may be used to endorse or promote products derived from
"     this software without specific prior written permission of
"     Eric Van Dewoestine.
"
"   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
"   IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
"   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
"   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
"   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
"   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
"   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
"   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
"   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
"   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
"   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
" }}}

" Global Variables {{{

if !exists('g:CopyrightEnabled')
  let g:CopyrightEnabled = 1
endif

if !exists('g:CopyrightPattern')
  " group 1 must be the text leading up to the most recent year
  " group 2 must be the most recent year to check against the current year.
  let g:CopyrightPattern = '\(Copyright.\{-}\%\(\d\{4}\s*[-,]\s*\)\{0,1}\)\(\d\{4}\)'
endif

if !exists('g:CopyrightAddRange')
  let g:CopyrightAddRange = 1
endif

if !exists('g:CopyrightMaxLines')
  let g:CopyrightMaxLines = 25
endif

" }}}

if !g:CopyrightEnabled
  finish
endif

" Script Variables {{{
let s:year = exists('*strftime') ? strftime('%Y') : '2012'
" }}}

" Autocmds {{{
augroup copyright
  autocmd!
  autocmd BufWrite * call <SID>UpdateCopyright()
augroup END
" }}}

function! s:UpdateCopyright() " {{{
  if exists('b:copyright_checked') || !&modified
    return
  endif

  let winview = winsaveview()
  let pos = getpos('.')
  try
    call cursor(1, 1)
    let lnum = search(g:CopyrightPattern, 'cnW', g:CopyrightMaxLines)
    if lnum == 0
      return
    endif

    let line = getline(lnum)
    let year = substitute(line, '.\{-}' . g:CopyrightPattern . '.*', '\2', '')
    if year == s:year
      return
    endif

    echohl WarningMsg
    try
      try
        " use unsilent to force prompt messages to show up even if the writing
        " of the file was issued with 'silent'.
        unsilent let response =  s:Prompt()
      catch /E492/
        " handle case where unsilent is not available
        let response =  s:Prompt()
      endtry
    finally
      echohl None
    endtry

    if response == '' || response !~ '\c\s*\(y\(es\)\?\)\s*'
      return
    endif
    if g:CopyrightAddRange && line !~ '\d\{4}\s*[-,]\s*' . year
      let sub = '\1' . year . ' - ' . s:year
    else
      let sub = '\1' . s:year
    endif
    call setline(lnum, substitute(line, g:CopyrightPattern, sub, ''))
    redraw " prevent the hit enter prompt
  finally
    call setpos('.', pos)
    call winrestview(winview)
    let b:copyright_checked = 1
  endtry
endfunction " }}}

function! s:Prompt() " {{{
  redraw
  echo printf(
    \ "Copyright year for file '%s' appears to be out of date.\n",
    \ expand('%:t'))
  let response = input("Would you like to update it? (y/n): ")
  while response != '' && response !~ '^\c\s*\(y\(es\)\?\|no\?\|\)\s*$'
    let response = input("You must choose either y or n. (Ctrl-C to cancel): ")
  endwhile
  return response
endfunction " }}}

" vim:ft=vim:fdm=marker
