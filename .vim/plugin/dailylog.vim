" Author: Eric Van Dewoestine
"
" Description:
"   Plugin for managing daily log entries to keep track of and reporting time
"   spent on tasks.
"
"   DailyLogOpen: Opens the current daily log file in a new window.
"   Optionally the command may be followed by the date you wish to open the
"   log for.
"     Ex. Open the current log file
"       :DailyLogOpen
"     Ex. Open the log file for January 15th 2005
"       :DailyLogOpen 2005-01-15
"
"   DailyLogStart: Opens the current daily log file if necessary and starts a
"   new log entry.
"
"   DailyLogStop: Opens the current daily log file if necessary and stops the
"   currently unfinished entry.  If more than one entry is unfinished, then
"   you will be prompted for the entry to stop.
"
"   DailyLogRestart: Opens the current daily log file if necessary and prompts
"   you for the entry to restart.
"
"   DailyLogReport: Aggregates per task and total times and updates the file
"   with reports of time spent on each task and overall.
"
"   DailyLogSearch: Searches your configured daily log directory via vimgrep
"   using the supplied pattern.
"     Ex. Search for "vim plugin"
"       :DailyLogSearch /vim plugin/
"
" License: {{{
"   Copyright (c) 2004 - 2009, Eric Van Dewoestine
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
if !exists(":DailyLogOpen")
  command -nargs=? -complete=customlist,dailylog#CommandCompleteDate
    \ DailyLogOpen :call dailylog#Open('<args>')

  command -nargs=+ DailyLogSearch :call dailylog#Search(<q-args>)
  command DailyLogStop            :call dailylog#Stop()
  command DailyLogStart           :call dailylog#Start()
  command DailyLogRestart         :call dailylog#Restart()
endif
" }}}

" vim:ft=vim:fdm=marker
