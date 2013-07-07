" Author:  Eric Van Dewoestine

source $VIMRUNTIME/syntax/groovy.vim

" this line in vim's groovy.vim breaks highlighting of multi line comments:
"syn region groovyString start='/[^/]' end='/' contains=groovySpecialChar,groovyRegexChar,groovyELExpr
" re-defining the multi line comments here fixes the issue.

syn region  groovyComment start="/\*"  end="\*/" contains=@groovyCommentSpecial,groovyTodo,@Spell
syn region  groovyDocComment start="/\*\*" end="\*/" keepend contains=groovyCommentTitle,@groovyHtml,groovyDocTags,groovyTodo,@Spell
