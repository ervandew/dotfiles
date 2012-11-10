" Author:  Eric Van Dewoestine

function! s:CrontabTemplate() " {{{
  if line('$') == 1 && getline(1) == ''
    call append(0, [
      \ '# minute (0-59),',
      \ '# |         hour (0-23),',
      \ '# |         |         day of the month (1-31),',
      \ '# |         |         |         month of the year (1-12),',
      \ '# |         |         |         |         day of the week (0-6 with 0=Sunday).',
      \ '# |         |         |         |         |           commands',
      \ '#----------------( minute cron jobs )--------------#',
      \ '#  *         *         *         *         *           /some/command.sh',
      \ '#----------------( hourly cron jobs )--------------#',
      \ '# 00         *         *         *         *           /some/command.sh',
      \ '#----------------( daily cron jobs )---------------#',
      \ '# 00        21         *         *         *           /some/command.sh',
      \ '#----------------( weekly cron jobs )--------------#',
      \ '# 00        21         *         *         0           /some/command.sh',
      \ '#----------------( monthly cron jobs )-------------#',
      \ '# 00        21        01         *         *           /some/command.sh',
      \ '#----------------( yearly cron jobs )--------------#',
      \ '# 00        21        01        01         *           /some/command.sh',
    \ ])
  endif
endfunction " }}}

call s:CrontabTemplate()

" vim:ft=vim:fdm=marker
