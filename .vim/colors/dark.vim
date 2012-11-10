" Author: Eric Van Dewoestine
"
" Vim color file initially based on ir_black.

set background=dark
hi clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name="dark"

" Main Color Groups {{{
hi Normal       ctermfg=white    ctermbg=NONE   cterm=NONE    guifg=#f6f3e8 guibg=#222222 gui=NONE

hi Cursor       ctermfg=black    ctermbg=gray   cterm=reverse guifg=black   guibg=gray    gui=NONE
hi Constant     ctermfg=green    ctermbg=NONE   cterm=NONE    guifg=#99CC99 guibg=NONE    gui=NONE
hi Comment      ctermfg=darkgray ctermbg=NONE   cterm=NONE    guifg=#7C7C7C guibg=NONE    gui=NONE
hi Conditional  ctermfg=blue     ctermbg=NONE   cterm=NONE    guifg=#6699CC guibg=NONE    gui=NONE

hi Delimiter    ctermfg=green    ctermbg=NONE   cterm=NONE    guifg=#99CC99 guibg=NONE    gui=NONE
hi Directory    ctermfg=blue     ctermbg=NONE   cterm=NONE    guifg=#96CBFE guibg=NONE    gui=NONE

hi Error        ctermfg=red      ctermbg=NONE   cterm=NONE    guifg=#FF6C60 guibg=NONE    gui=BOLD
hi ErrorMsg     ctermfg=white    ctermbg=red    cterm=NONE    guifg=white   guibg=#FF6C60 gui=NONE

hi Folded       ctermfg=darkgray ctermbg=NONE   cterm=NONE    guifg=#7C7C7C guibg=NONE    gui=NONE
hi FoldColumn   ctermfg=white    ctermbg=none   cterm=NONE    guifg=white   guibg=#222222 gui=NONE
hi Function     ctermfg=brown    ctermbg=NONE   cterm=NONE    guifg=#E18964 guibg=NONE    gui=NONE

hi Identifier   ctermfg=magenta  ctermbg=NONE   cterm=NONE    guifg=#C6C5FE guibg=NONE    gui=NONE
hi Ignore       ctermfg=darkgray ctermbg=NONE   cterm=NONE    guifg=#7c7c7c guibg=NONE    gui=NONE

hi Keyword      ctermfg=blue     ctermbg=NONE   cterm=NONE    guifg=#96CBFE guibg=NONE    gui=NONE
hi LineNr       ctermfg=238      ctermbg=NONE   cterm=NONE    guifg=#3D3D3D guibg=#222222 gui=NONE
hi ModeMsg      ctermfg=white    ctermbg=NONE   cterm=NONE    guifg=#CCCCCC guibg=NONE    gui=NONE
hi NonText      ctermfg=black    ctermbg=NONE   cterm=NONE    guifg=#070707 guibg=#222222 gui=NONE
hi Number       ctermfg=magenta  ctermbg=NONE   cterm=NONE    guifg=#cf9ebe guibg=NONE    gui=NONE
hi Operator     ctermfg=blue     ctermbg=NONE   cterm=NONE    guifg=#6699CC guibg=NONE    gui=NONE
hi PreProc      ctermfg=blue     ctermbg=NONE   cterm=NONE    guifg=#96CBFE guibg=NONE    gui=NONE

hi Search       ctermfg=233      ctermbg=243    cterm=NONE    guifg=black   guibg=#888888 gui=NONE
hi SignColumn   ctermfg=white    ctermbg=none   cterm=NONE    guifg=white   guibg=#222222 gui=NONE
hi Special      ctermfg=brown    ctermbg=NONE   cterm=NONE    guifg=#E18964 guibg=NONE    gui=NONE
hi SpecialKey   ctermfg=233      ctermbg=235    cterm=NONE    guifg=#222222 guibg=#333333 gui=NONE
hi Statement    ctermfg=blue     ctermbg=NONE   cterm=NONE    guifg=#6699CC guibg=NONE    gui=NONE
hi StatusLine   ctermfg=white    ctermbg=236    cterm=NONE    guifg=#CCCCCC guibg=#303030 gui=NONE
hi StatusLineNC ctermfg=241      ctermbg=236    cterm=NONE    guifg=#626262 guibg=#303030 gui=NONE
hi String       ctermfg=green    ctermbg=NONE   cterm=NONE    guifg=#AECE91 guibg=NONE    gui=NONE

hi Title        ctermfg=NONE     ctermbg=NONE   cterm=NONE    guifg=#f6f3e8 guibg=NONE    gui=bold
hi Todo         ctermfg=yellow   ctermbg=NONE   cterm=bold    guifg=#c4c466 guibg=NONE    gui=bold
hi Type         ctermfg=blue     ctermbg=NONE   cterm=NONE    guifg=#6699CC guibg=NONE    gui=NONE

hi VertSplit    ctermfg=black    ctermbg=235    cterm=NONE    guifg=black   guibg=#303030 gui=NONE
hi Visual       ctermfg=233      ctermbg=gray   cterm=NONE    guifg=black   guibg=#bebebe gui=NONE
hi WarningMsg   ctermfg=yellow   ctermbg=NONE   cterm=NONE    guifg=#c4c466 guibg=NONE    gui=BOLD
hi WildMenu     ctermfg=black    ctermbg=yellow cterm=NONE    guifg=black   guibg=#c4c466 gui=NONE

hi link Boolean         Constant
hi link Character       Constant
hi link Conditional     Statement
hi link Debug           Special
hi link Define          PreProc
hi link Exception       Statement
hi link Float           Number
hi link Include         PreProc
hi link Label           Statement
hi link Macro           PreProc
hi link PreCondit       PreProc
hi link Repeat          Statement
hi link SpecialChar     Special
hi link SpecialComment  Comment
hi link StorageClass    Type
hi link Structure       Type
hi link Tag             Special
hi link Typedef         Type
" }}}

" Code Editing {{{
hi MatchParen  ctermfg=magenta ctermbg=NONE cterm=bold guifg=#cf9ebe guibg=NONE gui=bold
" }}}

" Completion Popup {{{
hi Pmenu     ctermfg=white ctermbg=240   cterm=NONE guifg=#f6f3e8 guibg=#444444 gui=NONE
hi PmenuSel  ctermfg=black ctermbg=green cterm=NONE guifg=#000000 guibg=#cae682 gui=NONE
hi PmenuSbar ctermfg=233   ctermbg=NONE  cterm=NONE guifg=#000000 guibg=NONE    gui=NONE
" }}}

" Cursor line / column {{{
hi CursorLine   ctermfg=NONE  ctermbg=235 cterm=NONE guifg=NONE    guibg=#262626 gui=NONE
hi CursorLineNr ctermfg=white ctermbg=235 cterm=NONE guifg=#ffffff guibg=#262626 gui=NONE
hi CursorColumn ctermfg=NONE  ctermbg=235 cterm=NONE guifg=NONE    guibg=#262626 gui=NONE
" }}}

" Diff {{{
hi DiffAdd     ctermfg=124 ctermbg=250  cterm=NONE guifg=#cf6171 guibg=#cccccc gui=NONE
hi DiffDelete  ctermfg=250 ctermbg=red  cterm=NONE guifg=white   guibg=#cf6171 gui=NONE
hi DiffChange  ctermfg=74  ctermbg=NONE cterm=NONE guifg=#4186be guibg=#333333 gui=NONE
hi DiffText    ctermfg=26  ctermbg=250  cterm=NONE guifg=#4186be guibg=#cccccc gui=NONE
" }}}

" Spellcheck {{{
hi SpellBad   ctermfg=red     ctermbg=none cterm=bold,underline gui=bold,underline guifg=#cf6171
hi SpellCap   ctermfg=blue    ctermbg=none cterm=bold,underline gui=bold,underline guifg=#4186be
hi SpellRare  ctermfg=magenta ctermbg=none cterm=bold,underline gui=bold,underline guifg=#cf9ebe
hi SpellLocal ctermfg=green   ctermbg=none cterm=bold,underline gui=bold,underline guifg=green
" }}}

" Tabs {{{
hi TabLine     ctermfg=241   ctermbg=235 cterm=NONE guifg=#626262 guibg=#262626 gui=NONE
hi TabLineSel  ctermfg=white ctermbg=235 cterm=NONE guifg=#CCCCCC guibg=#262626 gui=NONE
hi TabLineFill ctermfg=NONE  ctermbg=235 cterm=NONE guifg=NONE    guibg=#262626 gui=NONE
" }}}

" vim:nowrap:ft=vim:fdm=marker
