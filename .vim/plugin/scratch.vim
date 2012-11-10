" Author: Eric Van Dewoestine
"
" Description:
"   Plugin to provide quick access to a scratch buffer.  The :Scratch command
"   will open a temp buffer whose file type is the same as the file it was
"   invoked from, or you can optionally specify the file type you would like
"   by supplying it as an argument to the :Scratch command.  The contents of
"   the buffer will also be saved for you in files by filetype allowing you to
"   recall the last scratch contents for a particular file type using the
"   :ScratchPrevious command, which is available once you've opened a scratch
"   buffer (note: only one level of history is saved).
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

" Global Variables {{{
let g:ScratchDir = '~/.vim/scratch'
" }}}

" Commands {{{
  command -nargs=? Scratch :call <SID>Scratch(<q-args>)
" }}}

function! s:Scratch(ft) " {{{
  " open a new window with the same filetype as the current window or use the
  " supplied arg.

  let ft = len(a:ft) ? a:ft : &ft
  if ft == ''
    let ft = 'txt'
  endif

  let name = '[Scratch (' . ft . ')]'
  let escaped = '[[]Scratch (' . ft . ')[]]'
  if bufwinnr(escaped) != -1
    let index = 1
    while bufwinnr(escaped) != -1
      let name = '[Scratch_' . index . ' (' . ft . ')]'
      let escaped = '[[]Scratch_' . index . ' (' . ft . ')[]]'
      let index += 1
    endwhile
  endif

  silent exec 'botright 10split ' . escape(name, ' ')
  let &ft = ft
  setlocal winfixheight
  setlocal noswapfile
  setlocal nobuflisted
  setlocal buftype=nofile
  setlocal bufhidden=delete

  augroup scratch
    autocmd BufWinLeave <buffer> call s:SaveScratch()
  augroup END

  command -buffer -nargs=0 ScratchPrevious :call <SID>LoadScratch()
endfunction " }}}

function! s:SaveScratch() " {{{
  let dir = expand(g:ScratchDir)
  if !isdirectory(dir)
    call mkdir(dir)
  endif

  call writefile(getline(1, line('$')), dir . '/' . &ft)
endfunction " }}}

function! s:LoadScratch() " {{{
  let file = expand(g:ScratchDir) . '/' . &ft
  if filereadable(file)
    1,$delete _
    call append(1, readfile(file))
    1,1delete _
  endif
endfunction " }}}

" vim:ft=vim:fdm=marker
