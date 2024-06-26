" Author: Eric Van Dewoestine

if has('nvim')
  echoe 'Not compatible with neovim'
endif

" vim options {{{
  " disable vi compatability mode
  set nocompatible

  colorscheme dark     " set the color scheme

  set autoindent       " always set autoindenting on
  set backspace=2      " backspace over indent, eol, start
  set background=dark  " set the background to dark
  set cedit=<esc>      " <esc> on the command (:) mode goes to command edit.
  set clipboard=unnamed
  set complete-=i      " exclude include files
  set complete-=t      " exclude tags
  set complete-=u      " exclude unloaded buffers
  set completeopt=menuone,longest,preview
  set display=lastline " if last line doesn't fit on screen, show as much as possible.
  set expandtab        " expand tabs to spaces
  set fillchars=vert:\ ,fold:-
  set formatoptions+=n " support formatting of numbered lists.
  set history=50       " keep 50 lines of command line history
  set hlsearch         " highlight all search matches
  set incsearch        " do incremental searching
  set laststatus=2     " always show the status line.
  " show all tabs as >- and tailing spaces as -
  set list listchars=precedes:<,extends:>,tab:>-,trail:-
  set mouse=a          " primarily here so that paste w/ mouse works better
  set nobackup         " do not keep a backup file
  set number           " show line numbers
  " set the printer name to use (see 'Queue Name' at http://localhost:631/printers/)
  set printdevice=Home
  set printoptions=paper:letter,header:0,number:n
  set ruler            " show the cursor position all the time
  set scrolloff=5      " always keep 5 lines of context around the cursor
  set shiftwidth=2     " number of spaces used by indenting
  set showcmd          " display incomplete commands
  set showtabline=2    " always show the tabline
  set spellsuggest=10  " limit number of spelling suggestions to 10.
  set sidescroll=10    " minimum number of columns to scroll
  set sidescrolloff=20 " always keep 10 columns of horizontal context
  set splitbelow       " default :split to split files below the current window.
  set splitright       " default :vsplit to split files to the right of the current window.
  set ssop+=globals    " save global variables (required by some plugins to restore from session).
  set switchbuf=useopen,usetab
  " set the strings used for the tabline
  set tabline=%!TabLine()
  set tabstop=2        " set the default tab width
  set timeoutlen=500   " timeout on mappings in .5 second
  set updatetime=1000  " timeout in millis for CursorHold event and swap writting.
  set virtualedit=all  " prevent the cursor from bouncing around columns while scrolling.
  set visualbell t_vb= " turn off system beeps and visual flash
  " Note: both __pycache patterns are required for vim command and *Relative
  " completion, and the order of these patterns seems to matter
  set wildignore+=*.pyc,*.pyo,*/__pycache__,*/__pycache__/*,*.so
  set wildmenu         " for command completion, show menu of available results
  " for command completion, show menu of available results
  set wildmode=longest:full,full
  set wrap             " wrap text

  set statusline=%<%f%{%FF()%}\ %M\ %h%r%=%-10.(%l,%c%V\ b=%n,w=%{winnr()}%)\ %P
  function! FF()
    let stl = ''
    " show the quickfix title
    if &ft == 'qf'
      let stl = exists('w:quickfix_title') ? ' ' . w:quickfix_title : ''
    " for csv files, display which column the cursor is in
    elseif &ft == 'csv'
      if exists(':CSV_WCol')
        let stl = ' [col: ' . CSV_WCol('Name') . ' (' . CSV_WCol() . ')]'
      endif
    endif

    " show in the status line if the file is in dos format
    if &ff != 'unix'
      let stl = ' [' . &ff . ']' . stl
    endif

    if str2nr(g:actual_curwin) == win_getid()
      return '%#StatusLineFF#' . stl . '%*'
    endif
    return stl
  endfunction

  filetype plugin indent on

  " syntax highlighting
  if &t_Co > 2 || has("gui_running")
    syntax on
    if &term =~ '^rxvt-unicode\|256color'
      set t_Co=256
      " rxvt-unicode supports changing the cursor on the fly.
      let &t_EI = "\e[2 q" " normal: block
      let &t_SI = "\e[6 q" " insert: bar
      let &t_SR = "\e[4 q" " replace: underscore
    endif
  endif

  function! TabLine() " {{{
    if tabpagenr('$') == 1 && !exists('t:tab_name')
      return ''
    endif

    let line = ''
    for i in range(tabpagenr('$'))
      let n = i + 1
      " select the highlighting
      let line .= tabpagenr() == n ? '%#TabLineSel#' : '%#TabLine#'

      " create the tab label
      let buflist = tabpagebuflist(n)
      let winnr = tabpagewinnr(n)
      let name = fnamemodify(bufname(buflist[winnr - 1]), ':t')
      " if the status looks like a constant value, use that
      let status = gettabwinvar(n, winnr, '&statusline')
      if status =~ '^\w\{3,}'
        let name = status
      endif
      if name == ''
        let name = '[No Name]'
      endif

      let tab_name = gettabvar(n, 'tab_name')
      if bufname(buflist[0]) =~ '^term://.*:ranger.*'
        let name = ''
        let tab_name = ''
      endif

      if tab_name != ''
        " only show the vcs branch for the current tab so as to reduce time
        " spent on system calls when there are several tabs.
        if tabpagenr() == n
          try
            " don't perform any system calls in here because vim calls this
            " function too often (entering insert mode, scrolling started,
            " etc) and all kinds of oditities can crop up (rendering issues w/
            " phantom characters, p starts behaving like P, other weird
            " stuff). limiting external interaction to file reads seems to be
            " safe so far.
            let dotgit = finddir('.git', escape(getcwd(), ' ') . ';')
            if dotgit != ''
              let lines = readfile(dotgit . '/HEAD')
              let branch = len(lines) > 0 ? substitute(lines[0], 'ref: refs/heads/', '', '') : ''
              if branch != ''
                let tab_name = tab_name . '(' . branch . ')'
              endif
            endif
          catch
            " ignore
          endtry
        endif
        let name = tab_name . ': ' . name
      endif
      let line .= ' %{"' . name . '"} '
      if n > 0 && n != tabpagenr('$')
        let line .= '%#TabLine# | '
      endif
    endfor

    " after the last tab fill with TabLineFill and reset tab page nr
    let line .= '%#TabLineFill#%T'
    return line
  endfunction " }}}
" }}}

" mappings {{{
  " sets the value of <Leader>
  let mapleader=","

  " scrolling just the viewpane
  nnoremap <c-j> <c-e>
  nnoremap <c-k> <c-y>

  " navigate windows
  nnoremap <silent> <tab><tab> :winc p<cr>
  nnoremap <silent> <tab>j :winc j<cr>
  nnoremap <silent> <tab>k :winc k<cr>
  nnoremap <silent> <tab>l :winc l<cr>
  nnoremap <silent> <tab>h :winc h<cr>
  nnoremap <silent> <tab>m :winc x<cr>
  nnoremap  <leader>p :call <SID>PickWindow()<cr>
  function! s:PickWindow() " {{{
    let max = winnr('$')
    let result = input('Window #: ')
    mode
    if result == ''
      return
    endif

    let num = str2nr(result)
    if num < 1 || num > max
      echohl WarningMsg | echo 'Invalid window number:' result | echohl None
      return
    endif
    exec num . 'winc w'
  endfunction " }}}

  " back tick works like single quote for jumping to a mark, but restores the
  " column position too.
  nnoremap ' `

  " use - to jump to front of text since _ requires an extra key
  nnoremap - _

  " redraw screen + clear search highlights + update diffs
  nnoremap <silent> <c-l> :nohl \| diffu<cr><c-l>
  nnoremap <silent> <c-l><c-l> :syn sync minlines=500<cr>

  " mappings to jump to the nearest { or }
  nnoremap {{ [{
  nnoremap }} ]}

  " toggle wrapping of text
  nmap <silent> <leader>w :let &wrap = !&wrap<cr>

  " toggle diff of the current buffer
  nmap <expr> <leader>d &diff ? ":diffoff\<cr>" : ":diffthis\<cr>"

  " toggle quickfix/location lists
  nmap <expr> <leader>ct &ft == 'qf' ? ":cclose\<cr>" : ":copen\<cr>""
  nmap <expr> <leader>lt &ft == 'qf' ? ":lclose\<cr>" : ":lopen\<cr>""

  " write and go to next quickfix/location list result
  nmap <silent> <leader>cn :call <SID>NextError('c', 0)<cr>
  nmap <silent> <leader>cf :call <SID>NextError('c', 1)<cr>
  nmap <silent> <leader>ln :call <SID>NextError('l', 0)<cr>
  function! s:NextError(list, nextfile) " {{{
    let error_count = (a:list == 'c') ? len(getqflist()) : len(getloclist(0))
    noautocmd silent update
    let command = a:list . 'nfile'
    if !a:nextfile
      " check new error count to handle case where writing the file modifies
      " the results.
      let length = (a:list == 'c') ? len(getqflist()) : len(getloclist(0))
      let command = (length == error_count) ? a:list . 'next' : a:list . a:list
    endif
    try
      exec command
      " WinEnter is not fired by default for some reason, so force it to
      " execute so we get our cursorline set by the autocmd setup elsewhere in
      " this file.
      doautocmd WinEnter %
      normal! zv
    catch /E553/
      echohl WarningMsg | echo 'No more items' | echohl None
    endtry
  endfunction " }}}

  " open the quickfix/location list and jump to the first entry for the line
  " under the cursor
  nmap <silent> <leader>cc :call <SID>CurrentError('c')<cr>
  nmap <silent> <leader>ll :call <SID>CurrentError('l')<cr>
  function! s:CurrentError(list) " {{{
    let pos = getcurpos()
    let lnum = line('.')
    exec a:list . 'open'
    call cursor(1, 1)
    let found = search('|' . pos[1] . '\>')
    if found
      exec line('.') . a:list . a:list
      call cursor(lnum, pos[2])
      exec a:list . 'open'
    else
      echohl WarningMsg
      echo 'No list item found for line' lnum
      echohl None
    endif
  endfunction " }}}

  " resize windows w/ arrow keys
  nnoremap <silent> <up> :resize +3<cr>
  nnoremap <silent> <down> :resize -3<cr>
  nnoremap <silent> <left> :vertical resize -3<cr>
  nnoremap <silent> <right> :vertical resize +3<cr>

  " allow g. to move back through the change list (like the single use '.)
  nnoremap <silent> g. g;
  " map '. to use changelist operation so that if the location isn't the one I
  " want, I don't have to hit g. twice just to get to the next change in the
  " list (wrapped in try since vim throws an error if already at the head of
  " the list and won't move the cursor).
  nnoremap <silent> '.
    \ :try \| exec 'normal! 999g,' \| catch /E663/ \| exec 'normal! `.' \| endtry<cr>

  " tab nav/manipulation mappings
  nnoremap <silent> gh :tabprev<cr>
  nnoremap <silent> gl :tabnext<cr>
  nnoremap <silent> gH :exec 'tabmove ' . max([tabpagenr() - 2, 0])<cr>
  nnoremap <silent> gL :exec 'tabmove ' . min([tabpagenr(), tabpagenr('$')])<cr>
  nnoremap <silent> g0 :tabfirst<cr>
  nnoremap <silent> g$ :tablast<cr>

  " gF is the same as gf + supports jumping to line number (file:100)
  nnoremap gf gF
  " map gF now to be the new window version of original gf
  nnoremap gF <c-w>F

  " modified version of '*' which doesn't move the cursor
  nnoremap <silent> * :let @/='\<<c-r>=expand("<cword>")<cr>\>'<cr>:set hls<cr>

  " toggle spelling with <c-z> (normal or insert mode)
  nnoremap <silent> <c-z>
    \ :setlocal spell! spelllang=en_us \|
    \ :echohl Statement \| echo 'spell check ' . (&spell ? 'on' : 'off') \| echohl None<cr>
  imap <c-z> <c-o><c-z>

  " preserve the " register when pasting over a visual selection
  xnoremap p <esc>:let reg = @"<cr>gvp:let @" = reg<cr>

  " virtualedit mappings to start insert no farther than the end of the actual
  " line
  function! s:VirtualEditEOLExpr(keys)
    " when starting insert on an empty line, start it at the correct indent
    if !len(getline('.')) && line('$') != 1
      " gross hack to temporarily set lazy redraw so the text doesn't shift
      " around when deleting the line, then using O to start a new one at the
      " correct indentation.
      set lz
      augroup temp_lz
        autocmd!
        autocmd CursorHold,CursorHoldI,InsertLeave <buffer> set nolz | autocmd! temp_lz
      augroup END
      return line('.') == line('$') ? "ddo" : "ddO"
    endif
    return (virtcol('.') > col('$') ? '$' : '') . a:keys
  endfunction
  nnoremap <expr> <silent> a <SID>VirtualEditEOLExpr('a')
  nnoremap <expr> <silent> i <SID>VirtualEditEOLExpr('i')

  " we only really need this command for its '-count=1' so that the paste
  " mapping below can accept a count and the yank mapping can take a range.
  command! -count=1 VirtualEditDisable set ve=
  " temporarily disable virtual edit when pasting/yanking to avoid behavior of
  " paste/yank in virtualedit mode (pasting past the end of the line, trailing
  " spaces on yank, etc).
  nnoremap <expr> <silent> p
    \ ':VirtualEditDisable<cr>' .
    \ (v:count ? v:count : '') . (v:register != '"' ? '"' . v:register : '') . 'p' .
    \ ':set ve=all<cr>'
" }}}

" commands {{{

  " Tab (open a new tab using the supplied working directory) {{{
  command! -nargs=1 -complete=dir Tab :call <SID>Tab('<args>')
  function! s:Tab(dir)
    if !isdirectory(a:dir)
      echohl Error | echom 'Not found:' a:dir | echohl None
      return
    endif

    let dir = fnamemodify(a:dir, ':p')
    if dir =~ '/$'
      let dir = dir[:-2]
    endif

    " if the current tab isn't already named, has no modifications, no
    " additional windows, and only an empty [No Name] buffer, then skip
    " opening a new tab and just name this one.
    if exists('t:tab_name') ||
     \ &modified ||
     \ winnr('$') > 1 ||
     \ expand('%') != '' ||
     \ line('$') != 1 ||
     \ getline(1) != ''
      tablast | tabnew
    endif
    let t:tab_name = fnamemodify(dir, ':t')
    exec 'tcd ' . escape(dir, ' ')

    set showtabline=2
    augroup tab
      autocmd!
      autocmd TabEnter *
        \ if tabpagenr('$') == 1 && !exists('t:tab_name') |
        \   set showtabline=1 |
        \ endif
    augroup END
  endfunction " }}}

  " Syntax (print the syntax name applied to the text under the cursor) {{{
  command! -nargs=0 Syntax
    \ echohl Statement |
    \ let id = synID(line('.'), col('.'), 1) |
    \ echo 'name: ' .  synIDattr(id, "name") |
    \ echo 'base: ' .  synIDattr(synIDtrans(id), "name") |
    \ echohl None
  " }}}

  " FormatJson (format a block of json using jshon) {{{
  command! -nargs=0 -range=% FormatJson :call <SID>FormatJson(<line1>, <line2>)
  function! s:FormatJson(line1, line2)
    let [line1, line2] = a:line1 < a:line2 ? [a:line1, a:line2] : [a:line2, a:line1]
    exec line1 . ',' . line2 . '!jshon -SC'
  endfunction " }}}

  " Incr (update visual block to increment numerically) {{{
  command! -range Incr :call <SID>Incr()
  function! s:Incr()
    let [l1, l2] = [line("'<"), line("'>")]
    let [c1, c2] = [col("'<"), col("'>")]
    if c1 > c2
      let [c1, c2] = [c2, c1]
    end

    if c1 == c2
      let pattern = '\(.*\)\(\%' . c1 . 'c\d\+\)\(.*\)'
    else
      let pattern = '\(.*\%' . c1 . 'c.*\)\(\d\+\)\(.*\%' . (c2 + 1) . 'c.*\)'
    endif

    let start = str2nr(substitute(getline(l1), pattern, '\2', ''))
    let incr = 1
    for lnum in range(l1, l2, l1 < l2 ? 1 : -1)[1:]
      if getline(lnum) =~ pattern
        exec lnum . 's/' . pattern . '/\1' . (start + incr) . '\3/'
        let incr += 1
      endif
    endfor
    call cursor(line("'<"), col("'<"))
  endfunction " }}}

  " SwapWords (swap 2 words using ,ws) {{{
  nnoremap <silent> <leader>ws :SwapWords<cr>
  command SwapWords :call <SID>SwapWords()
  function! s:SwapWords()
    " save the last search pattern
    let save_search = @/

    normal! "_yiw
    let pos = getpos('.')
    keepjumps s/\(\%#\w\+\)\(\_W\+\)\(\w\+\)/\3\2\1/
    call setpos('.', pos)

    " restore the last search pattern
    let @/ = save_search

    silent! call repeat#set(":call eclim#common#util#SwapWords()\<cr>", v:count)
  endfunction " }}}

  " OpenUrl (open url under the cursor) {{{
  command -nargs=0 OpenUrl :call s:OpenUrl()
  function! s:OpenUrl()
    let url = substitute(getline('.'),
      \ "\\(.*[[:space:]\"',(\\[{><]\\|^\\)\\(.*\\%" .
      \ col('.') . "c.\\{-}\\)\\([[:space:]\"',)\\]}<>].*\\|$\\)",
      \ '\2', '')

    if url == ''
      echohl Error
      echom 'No url supplied at command line or found under the cursor.'
      echohl None
      return
    endif

    " prepend http:// or file:// if no protocol defined.
    if url !~ '^\(https\?\|file\):'
      " absolute file on windows or unix
      if url =~ '^\([a-zA-Z]:[/\\]\|/\)'
        let url = 'file://' . url
      " everything else
      else
        let url = 'http://' . url
      endif
    endif

    silent exec '!xdg-open "' . url . '"'
    redraw
  endfunction " }}}

  " Mergetool (mergetool for git) {{{
  " .gitconfig
  "   [merge]
  "     tool = nvim
  "   [mergetool "nvim"]
  "     cmd = nvim -d -O3 "$LOCAL" "$BASE" "$REMOTE" "$MERGED" -c "Mergetool"
  command Mergetool :call <SID>Mergetool()
  function! s:Mergetool()
    if bufnr('$') != 4
      echohl Error | echom 'Unexpected number of buffers:' bufnr('$') | echohl NONE
      return
    endif

    if winnr('$') != 3
      echohl Error | echom 'Unexpected number of windows:' winnr('$') | echohl NONE
      return
    endif

    " relies on repo alias from my .gitconfg
    let branch = split(systemlist('git repo')[0], ':')[1]
    let files = [
      \ ['REMOTE', 'MERGING IN'],
      \ ['BASE', 'COMMON BASE'],
      \ ['LOCAL', 'CURRENT BRANCH'],
    \ ]
    if branch == 'rebase'
      " with a rebase the current branch becomes the REMOTE since it is
      " applied last, and the LOCAL is the other branch that we are attempting
      " to rebase on top of.
      let files = [
        \ ['REMOTE', 'CURRENT BRANCH'],
        \ ['BASE', 'COMMON BASE'],
        \ ['LOCAL', 'REBASE ONTO'],
      \ ]
    endif

    for [name, display] in files
      let pattern = '*_' . name . '_*'
      let winnr = bufwinnr(pattern)
      if winnr == -1
        echohl Error | echom 'Missing expected file:' pattern | echohl NONE
        return
      endif
      exec winnr . 'winc w'
      exec 'setlocal statusline=' . escape(display, ' ')
    endfor

    let merge = bufname(4)
    exec 'bot diffsplit' merge
  endfunction " }}}

" }}}

" abbreviations {{{
  cabbrev ln lnext
  cabbrev t  Tab
  cabbrev er EditRelative
  cabbrev rr ReadRelative
  cabbrev sr SplitRelative
" }}}

" autocommands {{{
    " For various events, check whether the file has been changed by another
    " process (only really useful in console vim where focus events aren't
    " fired).
    autocmd InsertEnter,WinEnter *
      \ if &buftype == '' && filereadable(expand('%')) |
      \   exec 'checktime ' . bufnr('%') |
      \ endif

    " when editing a file, jump to the last known cursor position.
    autocmd BufReadPost * silent! exec 'normal g`"'

    " disallow writing to read only files
    autocmd BufNewFile,BufRead * :let &modifiable = !&readonly

    " only highlight cursor line of the current window, making is easier to
    " pick out which window has focus
    if &term =~ '^\(rxvt-unicode\|.*256color\)' || has('gui_running')
      autocmd WinLeave * setlocal nocursorline
      autocmd WinEnter,VimEnter *
        \ exec 'setlocal ' . (&ft == 'qf' ? 'no' : '') . 'cursorline'
    endif
" }}}

" plugin specific settings
if filereadable(expand('~/.vimrc.plugins')) | source ~/.vimrc.plugins | endif
" settings specific to my day job
if filereadable(expand('~/.vimrc.work')) | source ~/.vimrc.work | endif

" prevent ctrl-s from suspending terminal updates when vim is running
silent !stty -ixon

" vim:ft=vim:fdm=marker
