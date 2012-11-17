" Vim indent file
" Language:	Java
" Maintainer:	Toby Allsopp <toby.allsopp@peace.com> (resigned)
" Last Change:	2005 Mar 28

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

" Indent Java anonymous classes correctly.
setlocal cindent cinoptions& cinoptions+=j1

" The "extends" and "implements" lines start off with the wrong indent.
setlocal indentkeys& indentkeys+=0=extends indentkeys+=0=implements indentkeys+=0=throws

" Set the function to do the work.
setlocal indentexpr=GetJavaIndent()

let b:undo_indent = "set cin< cino< indentkeys< indentexpr<"

" Only define the function once.
if exists("*GetJavaIndent")
  finish
endif

function! SkipJavaBlanksAndComments(startline)
  let lnum = a:startline
  while lnum > 1
    let lnum = prevnonblank(lnum)
    if getline(lnum) =~ '\*/\s*$'
      while getline(lnum) !~ '/\*' && lnum > 1
        let lnum = lnum - 1
      endwhile
      if getline(lnum) =~ '^\s*/\*'
        let lnum = lnum - 1
      else
        break
      endif
    elseif getline(lnum) =~ '^\s*//'
      let lnum = lnum - 1
    else
      break
    endif
  endwhile
  return lnum
endfunction

function GetJavaIndent()

  " Java is just like C; use the built-in C indenting and then correct a few
  " specific cases.
  let theIndent = cindent(v:lnum)

  " If we're in the middle of a comment then just trust cindent
  if getline(v:lnum) =~ '^\s*\*'
    return theIndent
  endif

  " find start of previous line, in case it was a continuation line
  let lnum = SkipJavaBlanksAndComments(v:lnum - 1)
  let prev = lnum
  while prev > 1
    let next_prev = SkipJavaBlanksAndComments(prev - 1)
    if getline(next_prev) !~ ',\s*$'
      break
    endif
    let prev = next_prev
  endwhile

  " Try to align "throws" lines for methods and "extends" and "implements" for
  " classes.
  if getline(v:lnum) =~ '^\s*\(extends\|implements\)\>'
        \ && getline(lnum) !~ '^\s*\(extends\|implements\)\>'
        \ && (indent(prev) == indent(v:lnum) || theIndent == indent(prev))
    let theIndent = theIndent + &sw
  endif

  " correct for continuation lines of "throws", "implements" and "extends"
  let cont_kw = matchstr(getline(prev),
        \ '^\s*\zs\(implements\|extends\)\>\ze.*,\s*$')
  if strlen(cont_kw) > 0
    let amount = strlen(cont_kw) + 1
    if getline(lnum) !~ ',\s*$'
      let theIndent = theIndent - (amount + &sw)
      if theIndent < 0
        let theIndent = 0
      endif
    elseif prev == lnum
      let theIndent = theIndent + amount
      if cont_kw ==# 'throws'
        let theIndent = theIndent + &sw
      endif
    endif
  elseif getline(prev) =~ '^\s*\(throws\|implements\|extends\)\>'
        \ && (getline(prev) =~ '{\s*$'
        \  || getline(v:lnum) =~ '^\s*{\s*$')
    let theIndent = indent(prev) - &sw
  endif

  " When an annotation is added, 'throws' indentation on methods breaks
  if getline(v:lnum) =~ '^\s*throws' && indent(prev) == theIndent
    let theIndent = indent(prev) + &sw
  endif

  " correct indentation of { if used on the rhs of an assignment (like an
  " array assignment).
  " FIXME: This one may be a matter of personal preference.  Some people may
  " want the default behavior, so should create a global variable if I intend
  " to submit this to vim.
  if getline(v:lnum) =~ '^\s*{' && getline(prev) =~ '=\s*$'
    if indent(lnum) == indent(prev)
      let theIndent = theIndent + &sw
    endif
  endif

  " new lines after an annotation need not be indented (unless continuation of
  " the annotation usage).
  if getline(prev) =~ '^\s*@[[:alpha:]]' && getline(prev) !~ '[{,]\s*$'
    if indent(prev) < theIndent
      let theIndent = theIndent - &sw
    endif
  endif

  " make sure a closing ')' on its own line which closes an annotation is
  " indented properly.
  if getline(v:lnum) =~ '^\s*)\s*$'
    let annot = SkipJavaBlanksAndComments(prev - 1)
    while annot > 1 && indent(annot) != (indent(lnum) - &sw)
      let annot = SkipJavaBlanksAndComments(annot - 1)
    endwhile

    if getline(annot) =~ '^\s*@[[:alpha:]]'
      let theIndent = theIndent - &sw
    endif

  " handle indentation after closing of an annotation block.
  "
  " @Table(name="blah",
  "   uniqueConstraints="some stuff"
  " )
  " public void test(){
  " }
  elseif getline(prev) =~ '^\s*)'
    let annot = SkipJavaBlanksAndComments(prev - 1)
    while annot > 1 && indent(annot) != indent(lnum)
      let annot = SkipJavaBlanksAndComments(annot - 1)
    endwhile

    if getline(annot) =~ '^\s*@[[:alpha:]]'
      let theIndent = theIndent - &sw
    endif

  " when closing paren ends a line, push next line back if not already
  "elseif getline(prev) =~ ')\s*$'
  "  if indent(prev) < theIndent
  "    let theIndent = theIndent - &sw
  "  endif
  endif

  " When the line starts with a }, try aligning it with the matching {,
  " skipping over "throws", "extends" and "implements" clauses.
  if getline(v:lnum) =~ '^\s*}\s*\(//.*\|/\*.*\)\=$'
    call cursor(v:lnum, 1)
    silent normal %
    let lnum = line('.')
    if lnum < v:lnum
      while lnum > 1
        let next_lnum = SkipJavaBlanksAndComments(lnum - 1)
        if getline(lnum) !~ '^\s*\(throws\|extends\|implements\)\>'
              \ && getline(next_lnum) !~ ',\s*$'
          break
        endif
        let lnum = prevnonblank(next_lnum)
      endwhile
      return indent(lnum)
    endif
  endif

  " Below a line starting with "}" never indent more.  Needed for a method
  " below a method with an indented "throws" clause.
  let lnum = SkipJavaBlanksAndComments(v:lnum - 1)
  if getline(lnum) =~ '^\s*}\s*\(//.*\|/\*.*\)\=$' && indent(lnum) < theIndent
    let theIndent = indent(lnum)
  endif

  return theIndent
endfunction

" Test Case
"
"@javax.persistence.TableGenerator(
"  name="EMP_GEN",
"  table="GENERATOR_TABLE",
"  pkColumnName = "key",
"  valueColumnName = "hi"
"  pkColumnValue="EMP",
"  allocationSize=20
")
"@javax.persistence.SequenceGenerator(
"  name="SEQ_GEN",
"  sequenceName="my_sequence"
")
"package test;
"
"public class Blah
"{
"  @AttributeOverrides( {
"    @AttributeOverride(name="iso2", column = @Column(name="bornIso2") ),
"    @AttributeOverride(name="name", column = @Column(name="bornCountryName") )
"  } )
"  private int id;
"
"  @Embedded
"  @AttributeOverrides( {
"    @AttributeOverride(name="city", column = @Column(name="fld_city") ),
"    @AttributeOverride(name="nationality.iso2", column = @Column(name="nat_Iso2") ),
"    @AttributeOverride(name="nationality.name", column = @Column(name="nat_CountryName") )
"    //nationality columns in homeAddress are overridden
"  } )
"  private Address homeAddress;
"
"  @Test ( name="blah",
"    type="int")
"  public void test()
"    throws Exception
"  {
"  }
"}

" vi: sw=2 et
