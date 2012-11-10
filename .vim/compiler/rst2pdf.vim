if exists("current_compiler")
  finish
endif
let current_compiler = "rst2pdf"

if exists(":CompilerSet") != 2    " older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

CompilerSet makeprg=rst2pdf\ %:p
CompilerSet errorformat=%f:%l:%m,%-G%.%#

" vim:ft=vim:fdm=marker
