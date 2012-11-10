" Author:  Eric Van Dewoestine

source $VIMRUNTIME/syntax/sql.vim

" only do spell checking on sql comments.
syn region sqlComment start="/\*"  end="\*/" contains=sqlTodo,@Spell
syn match sqlComment  "--.*$" contains=sqlTodo,@Spell

" vim:ft=vim:fdm=marker
