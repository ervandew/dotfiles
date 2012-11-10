" Author:  Eric Van Dewoestine
"
" Description:
"   Plugin for managing daily log entries.
"   See plugin/dailylog.vim for details.
"
" License: {{{
"   Copyright (c) 2004 - 2012, Eric Van Dewoestine
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
  if !exists("g:dailylog_home")
    let g:dailylog_home = expand('~/dailylog/')
  else
    if g:dailylog_home !~ '/$'
      let g:dailylog_home = g:dailylog_home . '/'
    endif
    let g:dailylog_home = expand(g:dailylog_home)
  endif
  if !exists("g:dailylog_path")
    let g:dailylog_path = '<year>-<month>-<day>.txt'
  endif
  if !exists("g:dailylog_delimiter")
    let g:dailylog_delimiter =
      \ "--------------------------------------------------------------------------------"
    let g:dailylog_delimiter_regex =
      \ '^' . g:dailylog_delimiter . '$'
  endif
  if !exists("g:dailylog_header")
    let g:dailylog_header =
        \ [g:dailylog_delimiter, "daily_log_<date>", g:dailylog_delimiter]
  endif
  if !exists("g:dailylog_entry_template")
    let g:dailylog_entry_template =
        \ ["<time> -", "\t<cursor>", "", g:dailylog_delimiter]
  endif
  if !exists("g:dailylog_win_cmd")
    let g:dailylog_win_cmd = 'botright split'
  endif
  if !exists("g:dailylog_link_cmd")
    let g:dailylog_link_cmd = 'aboveleft split <file>'
  endif
  if !exists("g:dailylog_win_size")
    let g:dailylog_win_size = 15
  endif
  if !exists("g:dailylog_time_pattern")
    let g:dailylog_time_pattern = '[0-9][0-9]:[0-9][0-9]'
  endif
  if !exists("g:dailylog_duration_pattern")
    let g:dailylog_duration_pattern = '\d\+hrs\. \d\+min\. (\d\+\.\d\+hrs\.)'
  endif
  if !exists("g:dailylog_delimiter_pattern")
    let g:dailylog_delimiter_pattern = '[-]\{5,}'
  endif
  if !exists("g:dailylog_summary_length")
    let g:dailylog_summary_length = 65
  endif
  if !exists("g:dailylog_time_report")
    let g:dailylog_time_report = '<hours>hrs. <mins>min. (<hours_decimal>hrs.)'
  endif
" }}}

" Script Variables {{{
  let s:time_range_pattern =
    \ '^\(\s*' .
    \ g:dailylog_time_pattern .
    \ '\s*-\s*' .
    \ g:dailylog_time_pattern .
    \ '\)\s*' .
    \ '\(' . g:dailylog_duration_pattern . '\)\?' .
    \ '$'

  let s:header_report_pattern =
    \ '^\(daily_log_.\{-}\)\s\+.*$'

  let s:browsers = [
      \ 'xdg-open', 'opera', 'firefox', 'konqueror',
      \ 'epiphany', 'mozilla', 'netscape', 'iexplore'
    \ ]

  let s:time_format = '%R'
" }}}

function! dailylog#Open(date) " {{{
  if !s:ValidateEnv()
    return
  endif

  let date = a:date
  if date == ""
    let date = strftime('%F')
  endif

  let parts = split(date, '-')
  let path = g:dailylog_path
  let path = substitute(path, '<year>', parts[0], '')
  let path = substitute(path, '<month>', parts[1], '')
  let path = substitute(path, '<day>', parts[2], '')
  let file = g:dailylog_home . path
  let dir = fnamemodify(file, ':h')
  if !isdirectory(dir)
    call mkdir(dir, 'p')
  endif

  if s:OpenFile(file)
    let header = g:dailylog_header
    call map(header, "substitute(v:val, '<date>', date, 'g')")
    call map(header, "substitute(v:val, '<file>', file, 'g')")
    call append(1, header)
    silent 1delete _
  endif
  call s:Syntax()
endfunction " }}}

function! dailylog#Start() " {{{
  call dailylog#Open("")

  let time = strftime(s:time_format)
  let entry = deepcopy(g:dailylog_entry_template)
  call map(entry, "substitute(v:val, '<time>', time, 'g')")

  call append(line('$'), entry)
  retab

  call s:StartInsert()
endfunction " }}}

function! dailylog#Stop() " {{{
  call dailylog#Open("")

  call cursor(1,1)

  " first get all open entries
  let line = 1
  let entry = -1
  while line
    let line = search(g:dailylog_time_pattern . ' -\s*$', 'W')
    if line != 0
      let entry = entry + 1
      let entries_{entry} = line
    endif
  endwhile

  if entry == -1
    echom "No unfinished entries found."
    return
  endif

  if entry != 0
    " build a summary for each entry to help user choose.
    let prompt = ""
    let index = 0
    while index <= entry
      let prompt = prompt . "\n" . index . ") " . s:Summarize(entries_{index})
      let index = index + 1
    endwhile
    let prompt = prompt . "\nChoose entry to stop: "

    " prompt the user for which entry they wish to stop.
    let result = s:Prompt(prompt, 0, entry)

    if result == ""
      echom "No entry chosen, aborting."
      return
    endif
  else
    let result = 0
  endif

  " stop the entry.
  let line = entries_{result}
  if line != 0
    call cursor(line, 1)

    let time = strftime(s:time_format)
    if getline(".") !~ '$\s'
      let time = " " . time
    endif

    call cursor(line("."), strlen(getline(".")))

    let save = @p
    let @p = time
    put p
    normal kJ
    let @p = save
  endif

endfunction " }}}

function! dailylog#Restart() " {{{
  call dailylog#Open("")

  call cursor(1,1)

  " first get all entries
  let line = 1
  let entry = -1
  while line
    let line = search(s:time_range_pattern, 'W')
    if line != 0 && s:IsCommentLine(line + 1)
      let entry = entry + 1
      let entries_{entry} = line
    endif
  endwhile

  if entry == -1
    echom "No entries found."
    return
  endif

  if entry != 0
    " build a summary for each entry to help user choose.
    let prompt = ""
    let index = 0
    while index <= entry
      let prompt = prompt . "\n" . index . ") " . s:Summarize(entries_{index})
      let index = index + 1
    endwhile
    let prompt = prompt . "\nChoose entry to restart: "

    " prompt the user for which entry they wish to restart.
    let result = s:Prompt(prompt, 0, entry)

    if result == ""
      echom "No entry chosen, aborting."
      return
    endif
  else
    let result = 0
  endif

  " restart the entry.
  let line = entries_{result}
  if line != 0
    call cursor(line, 1)

    let time = strftime(s:time_format)

    let save = @p
    let @p = time . " -"
    put p
    let @p = save
  endif

endfunction " }}}

function! dailylog#Report() " {{{
  let pos = getpos('.')
  call cursor(1,1)

  " first get all entries
  let line = 1
  let entries = -1
  let total_duration = 0
  while line
    let line = search(s:time_range_pattern, 'W')
    if line != 0 && getline(line - 1) =~ g:dailylog_delimiter_pattern
      let entries = entries + 1
      let dur = s:GetEntryDuration(line)
      let lastline = dur[0]
      let duration = dur[1]
      let total_duration = total_duration + duration
      let entry_report = s:Report(g:dailylog_time_report, duration)
      let updated = substitute(getline(lastline), s:time_range_pattern, '\1', '')
      call setline(lastline, updated . '    ' . entry_report)
    endif
  endwhile

  if entries == -1
    echom 'No entries found.'
    return
  endif

  let header = substitute(getline(2), s:header_report_pattern, '\1', '')
  let total_report = 'Total: ' . s:Report(g:dailylog_time_report, total_duration)
  call setline(2, header . '    ' . total_report)

  call setpos('.', pos)
endfunction " }}}

function! dailylog#Search(pattern) " {{{
  call dailylog#Open('')
  let path = g:dailylog_path
  let path = substitute(path, '<year>', '*', '')
  let path = substitute(path, '<month>', '*', '')
  let path = substitute(path, '<day>', '*', '')
  exec 'vimgrep ' . a:pattern . ' ' . g:dailylog_home . path
endfunction " }}}

function! dailylog#GoToBufferWindow(bufname) " {{{
  let winnr = bufwinnr(bufnr('^' . a:bufname))
  if winnr != -1
    exec winnr . "winc w"
  endif
endfunction " }}}

function! dailylog#CommandCompleteDate(argLead, cmdLine, cursorPos) " {{{
  let cmdLine = strpart(a:cmdLine, 0, a:cursorPos)
  let path = g:dailylog_path
  let path = substitute(path, '<year>', '*', '')
  let path = substitute(path, '<month>', '*', '')
  let path = substitute(path, '<day>', '*', '')

  let results = split(globpath(g:dailylog_home, path), '\n')
  let pattern = '.\{-}' . g:dailylog_path . '.\{-}'
  let pattern = substitute(pattern, '<\(year\|month\|day\)>', '\\(\\d\\+\\)', 'g')
  call map(results, 'substitute(v:val, pattern, "\\1-\\2-\\3", "")')
  call filter(results, 'v:val =~ "^" . a:argLead')

  return results
endfunction " }}}

function! s:Exec(cmd) " {{{
  " Executes system() accounting for possibly disruptive vim options.

  let saveshell = &shell
  let saveshellcmdflag = &shellcmdflag
  let saveshellpipe = &shellpipe
  let saveshellquote = &shellquote
  let saveshellredir = &shellredir
  let saveshellslash = &shellslash
  let saveshelltemp = &shelltemp
  let saveshellxquote = &shellxquote

  if has("win32") || has("win64")
    set shell=cmd.exe
    set shellcmdflag=/c
    set shellpipe=>%s\ 2>&1
    set shellquote=
    set shellredir=>%s\ 2>&1
    set noshellslash
    set shelltemp
    set shellxquote=
  else
    if executable('/bin/bash')
      set shell=/bin/bash
    else
      set shell=/bin/sh
    endif
    set shell=/bin/sh
    set shellcmdflag=-c
    set shellpipe=2>&1\|\ tee
    set shellquote=
    set shellredir=>%s\ 2>&1
    set noshellslash
    set shelltemp
    set shellxquote=
  endif

  exec a:cmd

  let &shell = saveshell
  let &shellcmdflag = saveshellcmdflag
  let &shellpipe = saveshellpipe
  let &shellquote = saveshellquote
  let &shellredir = saveshellredir
  let &shellslash = saveshellslash
  let &shelltemp = saveshelltemp
  let &shellxquote = saveshellxquote
endfunction " }}}

function! s:GetDuration(line) " {{{
  let time1 = substitute(a:line,
    \ '\s*\(' . g:dailylog_time_pattern . '\)\s*-.*', '\1', '')
  let time2 = substitute(a:line,
    \ '.*-\s*\(' . g:dailylog_time_pattern . '\).*', '\1', '')

  let time1 = substitute(
    \ system("date --date=\"" . time1 . "\" +%s"), '\n', '', '')
  let time2 = substitute(
    \ system("date --date=\"" . time2 . "\" +%s"), '\n', '', '')

  return time2 - time1
endfunction " }}}

function! s:GetEntryDuration(entry) " {{{
  let duration = 0

  let linenum = a:entry
  let line = getline(linenum)
  while line =~ s:time_range_pattern
    let line = substitute(line, s:time_range_pattern, '\1', '')
    call setline(linenum, line)
    let duration = duration + s:GetDuration(line)
    let linenum = linenum + 1
    let line = getline(linenum)
  endwhile

  return [linenum - 1, duration]
endfunction " }}}

function! s:IsCommentLine(line) " {{{
  let text = getline(a:line)
  if text !~ '^\s*$' &&
      \ text !~ '^' . g:dailylog_time_pattern &&
      \ text !~ g:dailylog_delimiter_pattern
    return 1
  endif

  return 0
endfunction " }}}

function! s:OpenFile(file) " {{{
  let isNew = 0
  " determine if the file is new.
  if !filereadable(a:file) && bufnr(a:file) == -1
    let isNew = 1
  endif

  " before opening it, see if it's in an open window or buffer
  if bufwinnr(bufnr(a:file)) != -1
    exec bufwinnr(bufnr(a:file)) . 'wincmd w'
  else
    let filename = expand('%:p')

    exec g:dailylog_win_cmd . ' ' . a:file
    exec "resize " . g:dailylog_win_size
    setlocal winfixheight
    setlocal nobuflisted bufhidden=delete

    let b:filename = filename
    augroup dailylog_temp_window
      autocmd! BufUnload <buffer>
      exec 'autocmd BufUnload <buffer> call dailylog#GoToBufferWindow("' .
        \ escape(b:filename, '\') . '")'
    augroup END

    noremap <silent> <buffer> <cr> :call <SID>OpenLink()<cr>
    command! -nargs=0 -buffer DailyLogReport :call dailylog#Report()
  endif

  return isNew
endfunction " }}}

function! s:OpenLink() " {{{
  let line = getline('.')
  let link = substitute(
    \ getline('.'), '.*|\(.\{-}\%' . col('.') . 'c.\{-}\)|.*', '\1', '')
  if link != line && filereadable(expand(link))
    echom 'link = ' . link
    silent exec substitute(g:dailylog_link_cmd, '<file>', link, 'g')
    return
  endif

  let link = substitute(
    \ getline('.'), '.*#\([0-9]\{-}\%' . col('.') . 'c.\{-}\)\(\W.*\|$\)', '\1', '')
  if link != line
    if !exists("g:dailylog_tracker_url")
      echoe "Linking to tickets requires setting " .
        \ "'g:dailylog_tracker_url' to be set."
      return
    endif
    let url = substitute(g:dailylog_tracker_url, '<id>', link, '')
    call s:OpenUrl(url)
  endif
endfunction " }}}

function! s:Prompt(prompt, min, max) " {{{
  let result = -1
  while result < a:min || result > a:max
    let result = input(a:prompt)
  endwhile

  return result
endfunction " }}}

function! s:Report(report, duration) " {{{
  let mins = a:duration / 60
  let hours = mins / 60
  if hours >= 1
    let mins = (a:duration - (hours * 60 * 60)) / 60
  endif

  " accuracy isn't to the 100ths, it's actually to the 1000ths
  let accuracy = 100
  let mins_decimal = (mins * accuracy) / 6
  let pad = strlen(accuracy) - strlen(mins_decimal)
  let index = 0
  while index < pad
    let mins_decimal = "0" . mins_decimal
    let index = index + 1
  endwhile

  let hours_decimal = hours . "." . mins_decimal

  let report = a:report
  let report = substitute(report, '<hours>', hours, 'g')
  let report = substitute(report, '<mins>', mins, 'g')
  let report = substitute(report, '<hours_decimal>', hours_decimal, 'g')

  return report

endfunction " }}}

function! s:StartInsert() " {{{
  if search('<cursor>')
    normal "_df>
    startinsert!
  endif
endfunction " }}}

function! s:Summarize(entry) " {{{
  call cursor(a:entry, 1)

  let line = 0
  while line == 0
    let text = getline(".")
    if text =~ g:dailylog_delimiter_pattern
      break
    elseif s:IsCommentLine(line("."))
      let line = line(".")
    else
      call cursor(line(".") + 1, 1)
    endif
  endwhile

  " no text found
  if line == 0
    return "No Summary."
  endif

  let summary = substitute(getline(line), '^\s\+', '', '')
  if strlen(summary) > g:dailylog_summary_length
    let summary = strpart(summary, 0, g:dailylog_summary_length - 3) . "..."
  endif
  return summary
endfunction " }}}

function! s:Syntax() " {{{
  set ft=dailylog
  hi link DailyLogTime Number
  hi link DailyLogDuration Statement
  hi link DailyLogDelimiter Comment
  hi link DailyLogLink Special
  " match time in the form of 08:12
  exec "syntax match DailyLogTime /" . g:dailylog_time_pattern . "/"
  " match durations in the form of 1hrs. 16min. (1.266hrs.)
  exec "syntax match DailyLogDuration /" . g:dailylog_duration_pattern . "/"
  exec "syntax match DailyLogDelimiter /" . g:dailylog_delimiter_pattern . "/"
  syntax match DailyLogLink /\(#[0-9]\+\||.\{-}|\)/
endfunction " }}}

function! s:ValidateEnv() " {{{
  if filewritable(g:dailylog_home) != 2
    echohl Error
    echo "Cannot write to directory '" . g:dailylog_home . "'."
    echo "Please create the directory or set g:dailylog_home to an existing directory."
    echohl Normal
    return 0
  endif
  if !exists("*strftime")
    echoe "Required function 'strftime()' not available on this system."
    return 0
  endif
  return 1
endfunction " }}}

function! s:OpenUrl(url) " {{{
  if !exists('s:browser') || s:browser == ''
    let s:browser = s:DetermineBrowser()

    " slight hack for IE which doesn't like the url to be quoted.
    if s:browser =~ 'iexplore'
      let s:browser = substitute(s:browser, '"', '', 'g')
    endif
  endif

  if s:browser == ''
    return
  endif

  let url = a:url
  let url = substitute(url, '\', '/', 'g')
  let url = escape(url, '&%')
  let url = escape(url, '%')
  let command = escape(substitute(s:browser, '<url>', url, ''), '#')
  silent! call s:Exec(command)
  redraw!

  if v:shell_error
    echohl Error
    echom "Unable to open browser:\n" . s:browser .
      \ "\nCheck that the browser executable is in your PATH " .
      \ "or that you have properly configured g:dailylog_browser"
    echohl Normal
  endif
endfunction " }}}

function! s:DetermineBrowser() " {{{
  let browser = ''

  " user specified a browser, we just need to fill in any gaps if necessary.
  if exists("g:dailylog_browser")
    let browser = g:dailylog_browser
    " add "<url>" if necessary
    if browser !~ '<url>'
      let browser = substitute(browser,
        \ '^\([[:alnum:][:blank:]-/\\_.:]\+\)\(.*\)$',
        \ '\1 "<url>" \2', '')
    endif

    if has("win32") || has("win64")
      " add 'start' to run process in background if necessary.
      if browser !~ '^[!]\?start'
        let browser = 'start ' . browser
      endif
    else
      " add '&' to run process in background if necessary.
      if browser !~ '&\s*$'
        let browser = browser . ' &'
      endif

      " add redirect of std out and error if necessary.
      if browser !~ '/dev/null'
        let browser = substitute(browser, '\s*&\s*$', '&> /dev/null &', '')
      endif
    endif

    if browser !~ '^\s*!'
      let browser = '!' . browser
    endif

  " user did not specify a browser, so attempt to find a suitable one.
  else
    if has("win32") || has("win64")
      " this version doesn't like .html suffixes on windows 2000
      "if executable('rundll32')
      "  let browser = '!rundll32 url.dll,FileProtocolHandler <url>'
      "endif
      " this doesn't handle local files very well or '&' in the url.
      "let browser = '!cmd /c start <url>'
      for name in s:win_browsers
        if executable(name)
          let browser = name
          break
        endif
      endfor
    elseif has("mac")
      let browser = '!open <url>'
    else
      for name in s:browsers
        if executable(name)
          let browser = name
          break
        endif
      endfor
    endif

    if browser != ''
      let g:dailylog_browser = browser
      let browser = s:DetermineBrowser()
    endif
  endif

  if browser == ''
    echohl Error
    echom "Unable to determine browser.  " .
      \ "Please set g:dailylog_browser to your preferred browser."
    echohl Normal
  endif

  return browser
endfunction " }}}

" vim:ft=vim:fdm=marker
