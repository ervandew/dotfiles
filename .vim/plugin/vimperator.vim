" Author: Eric Van Dewoestine
"
" Description: {{{
"   Plugin which is loaded when using vim as the editor from vimperator.
"   Provides support for saving the current buffer text by domain allowing you
"   to recall the last previous text (useful when the vim crashes, or the
"   website failed to post your text, etc.)
" }}}
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

if exists('vimperator_loaded') || expand('%:t') !~ '^vimperator-.*\.tmp$'
  finish
endif
let vimperator_loaded = 1

" Global Variables {{{

  if !exists("g:VimperatorEditHistoryStore")
    let g:VimperatorEditHistoryStore = '~/.vimperator/info/history-editor'
  endif

" }}}

" Autocmds {{{

  augroup vimperator_editor
    autocmd BufWritePost <buffer> call <SID>Save()
    " must be in a file that is loaded prior to vim firing this event (.vimrc)
    "autocmd SwapExists vimperator*.tmp call VimperatorEditorRecover(1)
    autocmd BufEnter vimperator*.tmp call VimperatorEditorRecover(2)
  augroup END

" }}}

" Commands {{{

  command VimperatorEditorPrevious :call <SID>RestorePrevious()

" }}}

" Mappings {{{

  " the current version of vim (7.2.182) sometimes crashes when applying a
  " spelling correction.
  nnoremap z= :call <SID>Save()<cr>z=

" }}}

function! VimperatorEditorRecover(stage) " {{{
  if a:stage == 1
    let v:swapchoice = 'd'
    let g:VimperatorEditorRecover = 1
  elseif exists('g:VimperatorEditorRecover')
    unlet g:VimperatorEditorRecover
    call s:RestorePrevious()
  endif
endfunction " }}}

function! s:Save() " {{{
  let domain = substitute(expand('%:t:r'), 'vimperator-\(.\{-}\)', '\1', '')
  let domain = substitute(domain, '-[0-9]\+$', '', '')

  let store = expand(g:VimperatorEditHistoryStore)
  let path = fnamemodify(store, ':h')
  if !isdirectory(path)
    call mkdir(path)
  endif

  let history = {}
  if filereadable(store)
    try
      let history = eval(readfile(store)[0])
    catch
      " ignore
    endtry
  endif

  let history[domain] = getline(1, '$')
  call writefile([string(history)], store)
endfunction " }}}

function! s:RestorePrevious() " {{{
  let domain = substitute(expand('%:t:r'), 'vimperator-\(.\{-}\)', '\1', '')
  let domain = substitute(domain, '-[0-9]\+$', '', '')

  let store = expand(g:VimperatorEditHistoryStore)
  if filereadable(store)
    try
      let history = eval(readfile(store)[0])
      if has_key(history, domain)
        silent 1,$delete _
        call append(1, history[domain])
        silent 1,1delete _
      else
        echo 'No previous text found: ' . domain
      endif
    catch
      " ignore
    endtry
  endif
endfunction " }}}

" vim:ft=vim:fdm=marker
