if exists("current_compiler")
  finish
endif
let current_compiler = "javac"

if exists(":CompilerSet") != 2    " older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

CompilerSet makeprg=javac\ $*\ *.java
CompilerSet errorformat=%E%f:%l:\ %m,%-Z%p^,%-C%.%#,%-G%.%#

" vim:ft=vim:fdm=marker
