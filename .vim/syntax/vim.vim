" Author:  Eric Van Dewoestine

source $VIMRUNTIME/syntax/vim.vim

syn clear vimRegister

" copied from orig syntax
" this first one screws up strings which happen to start with a register value
"syn match vimRegister	'[^,;]\zs"[a-zA-Z0-9.%#:_\-/]\ze[^a-zA-Z_":]'
syn match vimRegister	'\<norm\s\+\zs"[a-zA-Z0-9]'
syn match vimRegister	'\<normal\s\+\zs"[a-zA-Z0-9]'
syn match vimRegister	'@"'

" for some reason, this matcher breaks matching of some keywords (syntax, hi,
" etc) in function bodies if there is no space between the function name and
" open paren.
syn clear vimFuncBody
