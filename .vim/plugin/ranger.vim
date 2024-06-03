" Author: Eric Van Dewoestine
"
" Description: {{{
"   Plugin that allows the use of ranger (https://github.com/ranger/ranger) to
"   navigate and manage files from vim/neovim.
" }}}

" Command Declarations {{{
if exists(":Ranger") != 2
  command! -nargs=? -complete=file Ranger :call <SID>Ranger('<args>')
endif
" }}}

function! s:Ranger(path) " {{{
  for cmd in ['ranger', 'rifle', 'file']
    if !executable(cmd)
      echohl Error
      echom 'Missing required dependency:' cmd
      echohl None
      return
    endif
  endfor

  let path = a:path
  if path == ''
    let path = exists('t:ranger_path') ? t:ranger_path : getcwd()
  endif

  let choosefile = tempname()
  let ranger = 'ranger --choosefile=' . choosefile
  let ranger .= (isdirectory(path) ? ' ' : ' --selectfile=') . path

  if has('nvim')
    let tabnr = tabpagenr()
    tabnew | call termopen(ranger, {
      \ 'on_exit': function('s:OnExit'),
      \ 'choosefile': choosefile,
      \ 'tabnr': tabnr,
    \ })
    " empty status line (hide neovim's term:// naming)
    setlocal nonumber statusline=\ 
    startinsert
  else
    exec 'silent !' . ranger
    call s:Open(choosefile)
  endif
endfunction " }}}

function! s:OnExit(job_id, data, event) dict " {{{
  bdelete
  exec self.tabnr . 'tabn'
  call s:Open(self.choosefile)
endfunction " }}}

function! s:Open(choosefile) " {{{
  if filereadable(a:choosefile)
    let chosen = readfile(a:choosefile)[0]
    call delete(a:choosefile)

    let t:ranger_path = fnamemodify(chosen, ':p:h')

    let cwd_pattern = '^' . getcwd() . '/'
    if chosen =~ cwd_pattern
      let chosen = substitute(chosen, cwd_pattern, '', '')
    endif

    " list of file extensions that rifle might prefer to open in another
    " application, but should use the editor instead.
    let editor_overrides = ['html']
    let editor_override = index(editor_overrides, fnamemodify(chosen, ':e')) != -1

    " get the file type since rifle doesn't handle empty files as expected
    let file_type = system('file "' . chosen . '"')
    let file_type = substitute(file_type, '.*: \(.*\)\n', '\1', '')

    let action = split(system('rifle -l "' . chosen . '"'), '\n')[0]
    if action =~ ':editor:' || file_type == 'empty' || editor_override
      " First check if the file is already open, and if so just go to it
      let winnr = bufwinnr(bufnr('^' . chosen . '$'))
      if winnr != -1
        exec winnr . "winc w"
        return
      endif

      let cmd = 'split'
      " if the current buffer is an unmodified no name buffer, use edit
      if expand('%') == '' && !&modified && line('$') == 1 && getline(1) == ''
        let cmd = 'edit'
      endif
      exec cmd . ' ' chosen
    else
      let cmd = substitute(action, '\d\+:.\{-}:.\{-}:\(.*\)', '\1', '')
      let cmd = substitute(cmd, '\($@\|$1\)', chosen, '')
      silent! exec '!' cmd . ' &'
    endif
  endif

  redraw!
endfunction " }}}

" vim:ft=vim:fdm=marker
