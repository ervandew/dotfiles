if exists("current_compiler")
  finish
endif
let current_compiler = "scalac"

if exists(":CompilerSet") != 2    " older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

CompilerSet makeprg=scalac\ $*\ *.scala
CompilerSet errorformat=%E%f:%l:\ %m,%-Z%p^,%-C%.%#,%-G%.%#

" vim:ft=vim:fdm=marker
