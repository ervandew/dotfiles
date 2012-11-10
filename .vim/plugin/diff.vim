" Author: Eric Van Dewoestine
"
" Description:
"   Plugin to provide commands for navigating changes when using vim's diff
"   mode.  Differs from vim's default [c and ]c bindings in that these
"   commands jump to every change instead of skipping blocks of lines, and
"   also jumps to the changed text column instead of just the line.
"
" License: {{{
"   Copyright (c) 2009 - 2012, Eric Van Dewoestine
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

" Command Declarations {{{
if !exists(":DiffNextChange")
  command -count=1 DiffNextChange :call <SID>NextPrev(1, <count>)
  command -count=1 DiffPrevChange :call <SID>NextPrev(-1, <count>)
endif
" }}}

function! s:NextPrev(dir, count) " {{{
  if !&diff
    return
  endif

  let num = v:count > 0 ? v:count : a:count
  while num > 0
    let cur = synIDattr(diff_hlID(line('.'), col('.')), "name")
    if cur == 'DiffChange' || cur == 'DiffText'
      let col = col('.')
      if cur == 'DiffText'
        call s:NextPrevOnLine(a:dir, 'DiffChange')
      endif
      call s:NextPrevOnLine(a:dir, 'DiffText')
      if col != col('.')
        let num -= 1
        continue
      endif
    endif

    " handle blocks of changes which the default vim key bindings would skip.
    if cur =~ '^Diff'
      call cursor(line('.') + a:dir, 1)
      " edge case where next line is an add, so stop on it
      let cur = synIDattr(diff_hlID(line('.'), col('.')), "name")
      if cur == 'DiffAdd'
        if col('.') == 1 && getline(line('.'))[0] == ' '
          normal! _
        endif
        let num -= 1
        continue
      endif

      " re-execute the DiffChange/DiffText block above on the new line
      continue
    endif

    " FIXME: prev doesn't work as well since [c jumps to the start of a change
    " block, skipping other changes in the block that our command should
    " visit.  May need to abandon use of the vim bindings.
    exec 'normal! ' . (a:dir > 0 ? ']c' : '[c')
    call s:NextPrevOnLine(a:dir, 'DiffText\|DiffAdd')
    let num -= 1
  endwhile
endfunction " }}}

function! s:NextPrevOnLine(dir, name) " {{{
  let lnum = line('.')
  let line = getline('.')
  let index = (a:dir > 0 ? 0 : len(line) - 1)
  while (a:dir > 0 && index < len(line)) || (a:dir < 0 && index >= 0)
    if synIDattr(diff_hlID(lnum, index + 1), "name") =~ a:name
      call cursor(0, index + 1)
      " edge case where prev command needs to move the cursor to the front of
      " the change.
      if a:dir < 0
        while index >= 0 &&
            \ synIDattr(diff_hlID(lnum, index + 1), "name") =~ a:name
          let index -= 1
        endwhile
        call cursor(0, index + 2)
      endif
      break
    endif
    let index += a:dir
  endwhile

  if col('.') == 1 && line[0] == ' '
    normal! _
  endif
endfunction " }}}

" vim:ft=vim:fdm=marker
