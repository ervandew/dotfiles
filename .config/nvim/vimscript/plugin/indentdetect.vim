" Author: Eric Van Dewoestine
"
" Plugin to detect indentation settings (expandtab, shiftwidth, tabstop).
"
" Usage:
"   :IndentDetect
"     or as an autocmd
"   autocmd FileType * IndentDetect
"
" Config:
"   g:IndentDetectDefaults: dictionary whose keys are used as regex patterns
"   to match against files whose indent settings could not be determined, then
"   using the corresponding value dictionary as the default settings for that
"   file.  So, in this example if we couldn't determine the indent settings
"   for a file in ~/my/project/root, we'd use shiftwidth and tabstop of 4.
"
"       let g:IndentDetectDefaults = {
"           \ '~/my/project/root/': {'shiftwidth': 4, 'tabstop': 4}
"         \ }
"
"   g:IndentDetectForce: dictionary just like g:IndentDetectDefaults, but used
"   to force all matching files to use the supplied settings, bypassing any
"   indent detection.

" Global Variables {{{
if !exists('g:IndentDetectDefaults')
  let g:IndentDetectDefaults = {}
endif
if !exists('g:IndentDetectForce')
  let g:IndentDetectForce = {}
endif
" }}}

" Commands {{{
command! -nargs=? IndentDetect :call <SID>IndentDetect()
" }}}

function! s:IndentDetect() " {{{
  " the file may be set as txt first, which we'll ignore.
  if &ft == 'txt'
    return
  endif

  let options = ['expandtab', 'shiftwidth', 'tabstop']

  " check for modeline settings to prevent overriding them
  if &modeline
    for option in options
      redir => lastset
      silent exec 'verbose set ' . option . '?'
      redir END
      if lastset =~ '\<modeline\>'
        call remove(options, index(options, option))
      endif
    endfor
  endif

  " exit if all options have been set in the modeline
  if len(options) == 0
    return
  endif

  " look for configured forced options
  let forced = 0
  for key in keys(g:IndentDetectForce)
    if expand('%:p') =~ expand(key)
      let forced = 1
      if index(options, 'tabstop') != -1
        exec 'setlocal tabstop=' .
          \ get(g:IndentDetectForce[key], 'tabstop', &tabstop)

        " if softtabstop is set, make sure it mirrors the new tabstop value so
        " that backspacing over auto inserted indentation works as expected.
        if &softtabstop
          exec 'setlocal softtabstop=' . &tabstop
        endif
      endif

      if index(options, 'shiftwidth') != -1
        exec 'setlocal shiftwidth=' .
          \ get(g:IndentDetectForce[key], 'shiftwidth', &shiftwidth)
      endif
    endif
  endfor

  " if we applied forced options, then we're done.
  if forced
    return
  endif

  let pos = getpos('.')
  try
    call cursor(1, 1)

    let samples = {}
    let num_samples = 0
    let last_indent = 0

    let ts = v:false
    if has('nvim')
      let ts = luaeval('vim.treesitter.highlighter.active[' . bufnr() . '] ~= nil')
    endif

    " TODO: take samples from other parts of the file (middle, end)
    while num_samples < 5 && search('^\s\+\S', 'eW', 500, 500)
      if !s:Ignore(ts)
        let indent = indent(line('.'))

        " indents larget than the previous are probably line continuations,
        " etc.
        if last_indent != 0 && indent > last_indent
          continue
        endif

        " if the indent is greater than 4, then we are probably not on a
        " standard indent line.
        if indent > 4
          continue
        endif

        let sample = get(samples, indent, {})
        let samples[indent] = {
            \ 'line': get(sample, 'line', getline('.')),
            \ 'count': get(sample, 'count', 0) + 1
          \ }
        let num_samples += 1
        let last_indent = indent
      endif
    endwhile

    " find the indent with the most number of samples and use that
    let indent = &shiftwidth
    let max_samples = 0
    for ind in keys(samples)
      if samples[ind].count > max_samples
        let indent = ind
        let max_samples = samples[ind].count
      endif
    endfor

    if len(samples) > 0
      if samples[ind].line =~ '^\t'
        if index(options, 'expandtab') != -1
          setlocal noexpandtab
        endif
      endif

      " Note: currently mirroring tabstop + shiftwidth.
      if index(options, 'tabstop') != -1
        exec 'setlocal tabstop=' . indent

        " if softtabstop is set, make sure it mirrors the new tabstop value so
        " that backspacing over auto inserted indentation works as expected.
        if &softtabstop
          exec 'setlocal softtabstop=' . &tabstop
        endif
      endif

      if index(options, 'shiftwidth') != -1
        exec 'setlocal shiftwidth=' . indent
      endif

    else
      " no samples to work with, so check for a configured default for this
      " file's location
      for key in keys(g:IndentDetectDefaults)
        if expand('%:p') =~ expand(key)
          if index(options, 'tabstop') != -1
            exec 'setlocal tabstop=' .
              \ get(g:IndentDetectDefaults[key], 'tabstop', &tabstop)

            " if softtabstop is set, make sure it mirrors the new tabstop value so
            " that backspacing over auto inserted indentation works as expected.
            if &softtabstop
              exec 'setlocal softtabstop=' . &tabstop
            endif
          endif

          if index(options, 'shiftwidth') != -1
            exec 'setlocal shiftwidth=' .
              \ get(g:IndentDetectDefaults[key], 'shiftwidth', &shiftwidth)
          endif
        endif
      endfor
    endif

  finally
    call setpos('.', pos)
  endtry
endfunction " }}}

function! s:Ignore(ts) " {{{
  let syntax = ''
  if has('nvim') && a:ts == v:true
    try
      let syntax = luaeval('vim.treesitter.get_node():type()')
    catch /E5108/
      " treesitter state could change, so fallback to regular syntax check
    endtry
  endif

  if syntax == ''
    let synid = synIDtrans(synID(line('.'), col('.'), 1))
    let syntax = synIDattr(synid, "name")
  endif

  return syntax =~? 'comment\|string'
endfunction " }}}

" vim:fdm=marker
