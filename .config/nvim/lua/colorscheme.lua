local M = {}

local background = '#292929'
local white = '#cccccc'
local gray2 = '#222222'
local gray3 = '#333333'
local gray4 = '#444444'
local gray5 = '#555555'
local gray6 = '#666666'
local gray7 = '#777777'
local gray8 = '#888888'
local gray9 = '#999999'
local gray10 = '#aaaaaa'
local gray11 = '#bbbbbb'

local blue = '#708090'
local green = '#789978'
local green_dark = '#587958'
local orange = '#af875f'
local purple = '#875f87'
local red = '#964848'
local red_dark = '#624646'
local yellow = '#afaf5f'
local yellow_mid = '#8f8f3f'
local yellow_dark = '#5f5f0f'

local error= red
local warn = yellow
local info = '#878700'
local hint = '#7a7a7a'

M.init = function()
  local hl = function(...)
    vim.api.nvim_set_hl(0, ...)
  end

  hl('@attribute', { fg = gray6 })
  hl('@boolean', { fg = purple })
  hl('@comment', { fg = '#525252' })
  hl('@comment.documentation', { link = '@comment' })
  hl('@comment.error', { link = '@comment.todo' })
  hl('@comment.note', { fg = gray7 })
  hl('@comment.todo', { fg = yellow_mid })
  hl('@comment.warn', { fg = orange })
  hl('@constant.builtin', { fg = gray7 })
  hl('@constructor', { fg = gray8 })
  hl('@diff.minus', { fg = red })
  hl('@function', { fg = white })
  hl('@function.builtin', { fg = gray6 })
  hl('@function.call', { fg = gray7 })
  hl('@function.method', { fg = white })
  hl('@keyword', { fg = gray8 })
  hl('@keyword.return', { fg = green })
  hl('@number', { fg = red_dark })
  hl('@operator', { fg = gray7 })
  hl('@string.special', { fg = green })
  hl('@string.special.url.comment', { underline = false })
  hl('@tag', { fg = gray5 })
  hl('@variable', { fg = white })
  hl('@variable.builtin', { fg = gray10 })
  hl('@variable.parameter', { fg = gray8 })
  hl('Added', { fg = green })
  hl('Changed', { fg = gray7 })
  hl('Comment', { link = '@comment' })
  hl('ColorColumn', { bg = '#191919' })
  hl('Constant', { fg = gray10 })
  -- providing ctermfg prevents underline on DiffChange lines:
  -- bug: https://github.com/neovim/neovim/issues/9800.
  hl('CursorLine', { ctermfg = 'black', bg = '#202020' })
  hl('CursorLineNr', { fg = 'white', bg = '#202020' })
  hl('CurSearch', { link = 'CurSearchMain' })
  hl('Delimiter', { fg = gray7 })
  hl('DiffAdd', { fg = green, bg = background })
  hl('DiffChange', { fg = yellow_mid, bg = '#232323' })
  hl('DiffDelete', { fg = '#870000', bg = '#2f0000' })
  hl('DiffRemoved', { link = '@diff.minus' })
  hl('DiffText', { fg = yellow, bg = '#404040' })
  hl('Directory', { fg = gray5 })
  hl('EndOfBuffer', { fg = gray4 })
  hl('Error', { fg = error, bg = 'none' })
  hl('ErrorMsg', { link = 'Error' })
  hl('FloatBorder', { fg = gray6 })
  hl('FoldColumn', { link = 'Folded' })
  hl('Folded', { fg = '#5c5c5c', bg = 'none' })
  hl('Function', { fg = gray8 })
  hl('Identifier', { fg = gray10 })
  hl('IncSearch', { link = 'CurSearch' })
  hl('Keyword', { fg = gray6 })
  hl('LineNr', { fg = gray4 })
  hl('MatchParen', { fg = '#cf9ebe', bg = background })
  hl('ModeMsg', { fg = gray9 })
  hl('MoreMsg', { link = 'ModeMsg' })
  hl('MsgArea', { fg = white })
  hl('NonText', { fg = gray5 })
  hl('Normal', { fg = white, bg = 'none' })
  hl('NormalFloat', { link = 'Normal' })
  hl('NormalNC', { bg = '#1f1f1f' }) -- non-current window
  hl('Pmenu', { fg = '#7a7a7a', bg = gray2 })
  hl('PmenuSel', { bg = gray3 })
  hl('PreProc', { link = 'Keyword' })
  hl('Question', { fg = gray8 })
  hl('QuickFixLine', { fg = green })
  hl('Search', { fg = white, bg = '#607080' })
  hl('SignColumn', { bg = 'none' })
  hl('Special', { fg = blue })
  hl('SpellBad', { fg = '#cf6171', underline = true })
  hl('SpellCap', { fg = '#4186be', underline = true })
  hl('SpellRare', { fg = '#cf9ebe', underline = true })
  hl('SpellLocal', { fg = green, underline = true })
  hl('Statement', { fg = gray6 })
  hl('StatusLine', { fg = white, bg = background })
  hl('StatusLineNC', { fg = '#626262', bg = background })
  hl('StatusLineFF', { fg = '#c4c466', bg = background })
  hl('String', { fg = blue })
  hl('Substitute', { link = 'Search' })
  hl('TabLine', { fg = '#626262',  bg = background })
  hl('TabLineFill', { bg = background })
  hl('TabLineSel', { fg = white,  bg = background })
  hl('TabLineSelBranch', { fg = gray8, bg = background })
  hl('TermCursor', { fg = gray2, bg = '#acacac'})
  hl('Title', { fg = gray7 })
  hl('Type', { fg = gray10 })
  hl('Visual', { bg = '#353535' })
  hl('VisualCursor', { bg = '#d787d7' })
  hl('WarningMsg', { fg = warn })
  hl('Whitespace', { fg = gray4 })

  -- custom status line {{{
  -- indicate if the current file has lsp errors/warnings/etc.
  hl('DiagnosticStatusError', { fg = error, bg = background, italic = true })
  hl('DiagnosticStatusHint', { fg = hint, bg = background, italic = true })
  hl('DiagnosticStatusInfo', { fg = info, bg = background, italic = true })
  hl('DiagnosticStatusWarn', { fg = warn, bg = background, italic = true })

  -- current search info in the status line
  -- using several shades lighter than CurSearch (used by custom status line)
  hl('CurSearchStatus', { fg = '#a3c4a5', bg = background })
  -- using several shades lighter than Search (used by custom status line)
  hl('SearchStatus', { fg = '#a0b0c0', bg = background, bold = true })
  -- highlight the whole status line if the current file doesn't exist on disk
  hl('StatusLineMissingFile', { fg = yellow, bg = background, italic = true })
  -- }}}

  -- custom search {{{
  hl('CurSearchMain', { fg = white, bg = '#638465' })
  hl('CurSearchWrap', { fg = white, bg = '#8f5faf' })
  -- }}}

  -- css {{{
  hl('@tag.attribute.css', { fg = gray7 })
  -- }}}

  -- lsp {{{
  hl('@lsp.type.event.lua', { link = '@comment' })
  hl('DiagnosticHint', { fg = hint })
  hl('DiagnosticInfo', { fg = gray4 })
  hl('DiagnosticError', { link = 'Error' })
  hl('DiagnosticOk', { fg = green })
  hl('DiagnosticSignError', { link = 'DiagnosticError' })
  hl('DiagnosticSignInfo', { fg = info })
  hl('DiagnosticSignWarn', { link = 'WarningMsg' })
  hl('DiagnosticUnnecessary', { link = 'DiagnosticHint' })
  hl('DiagnosticUnderlineError', { fg = error, italic = true, underline = false })
  hl('DiagnosticUnderlineInfo', { fg = info, italic = true, underline = false })
  hl('DiagnosticUnderlineWarn', { fg = warn, italic = true, underline = false })
  hl('DiagnosticVirtualTextError', { link = 'DiagnosticError' })
  -- }}}

  -- git {{{
  hl('@constant.git_rebase', { fg = red_dark })
  hl('@markup.heading.gitcommit', { link = '@keyword' })
  hl('@string.special.url.gitcommit', { link = '@markup.link.gitcommit' })

  -- git.lua
  hl('GitAnnotate', { fg = gray6 })
  hl('GitAnnotateMe', { fg = purple })
  hl('GitAnnotateUncommitted', { fg = green })
  hl('GitAuthor', { fg = gray9 })
  hl('GitDate', { link = 'String' })
  hl('GitLink', { fg = gray8 })
  hl('GitLogBisectBad', { fg = red })
  hl('GitLogBisectBadFirst', { fg = red, bold = true })
  hl('GitLogBisectCurrent', { fg = yellow, bold = true })
  hl('GitLogBisectGood', { fg = green })
  hl('GitLogDiff', { fg = gray5 })
  hl('GitLogDiffAdd', { fg = green })
  hl('GitLogDiffDelete', { fg = red })
  hl('GitLogFiles', { fg = gray8 })
  hl('GitLogFileDoesNotExist', { fg = gray5 })
  hl('GitLogHeader', { fg = gray9 })
  hl('GitLogHeaderName', { fg = gray6 })
  hl('GitLogMarkerIn', { fg = red, bold = true })
  hl('GitLogMarkerOut', { fg = green, bold = true })
  hl('GitLogStatsChanged', { fg = yellow_dark })
  hl('GitLogStatsInserted', { fg = green_dark })
  hl('GitLogStatsDeleted', { fg = red_dark })
  hl('GitMessage', { fg = gray11 })
  hl('GitRefs', { fg = gray7 })
  hl('GitRevision', { fg = red_dark })
  hl('GitStatusAdded', { fg = green })
  hl('GitStatusAhead', { fg = green })
  hl('GitStatusBehind', { fg = red })
  hl('GitStatusBranchDescAhead', { fg = green })
  hl('GitStatusBranchDescTag', { link = 'GitRefs' })
  hl('GitStatusBranchLocal', { fg = green })
  hl('GitStatusBranchLocalBisect', { fg = yellow, bold = true  })
  hl('GitStatusBranchRemote', { fg = red_dark })
  hl('GitStatusComment', { link = 'Comment' })
  hl('GitStatusConflict', { fg = red })
  hl('GitStatusConflictDeleted', { fg = yellow })
  hl('GitStatusDeleted', { fg = blue })
  hl('GitStatusDeletedFile', { fg = gray5 })
  hl('GitStatusDeletedStaged', { fg = green })
  hl('GitStatusModified', { fg = blue })
  hl('GitStatusModifiedStaged', { fg = green })
  hl('GitStatusRenamedStaged', { fg = green })
  hl('GitStatusStash', { fg = gray7 })
  hl('GitStatusUntracked', { fg = gray8 })
  -- }}}

  -- html {{{
  hl('htmlEndTag', { fg = gray5 })
  hl('htmlH3', { fg = gray8 })
  hl('htmlTagName', { fg = gray7 })
  -- }}}

  -- ini {{{
  hl('@property.ini', { link = '@keyword' })
  hl('@type.ini', { link = 'Special' })
  -- }}}

  -- markdown {{{
  hl('@markup.heading', { fg = gray6, bold = true })
  hl('@markup.italic', { fg = gray8, italic = true })
  hl('@markup.link.label.markdown_inline', { fg = gray7 })
  hl('@markup.link.url.markdown_inline', { fg = gray4 })
  hl('@markup.list', { fg = gray6, bold = true })
  hl('@markup.quote', { fg = gray7 })
  hl('@markup.raw.block.markdown', { fg = gray6 })
  hl('@markup.raw.markdown_inline', { fg = gray6 })
  hl('@markup.strong', { fg = gray8, bold = true })
  -- }}}

  -- python {{{
  hl('@string.documentation.python', { fg = gray6 })
  hl('@number.float.python', { link = '@number' })
  -- }}}

  -- regex {{{
  hl('Regex0', { fg = '#00afff', underline = true })
  hl('Regex1', { fg = '#875fff', underline = true })
  hl('RegexGroup0', { fg = '#5fd75f', underline = true })
  hl('RegexGroup1', { fg = '#af87df', underline = true })
  -- }}}

  -- telescope {{{
  hl('TelescopeBorder', { fg = gray6 })
  hl('TelescopeMatching', { fg = purple })
  hl('TelescopePreviewLine', { bg = background })
  hl('TelescopeResultsComment', { fg = gray6 })
  hl('TelescopeResultsNormal', { fg = '#aaaaaa' })
  hl('TelescopeSelection', { fg = green, bg = '#121212' })

  -- git_status picker
  hl('TelescopeResultsDiffAdd', { fg = green, bold = true })
  hl('TelescopeResultsDiffChange', { fg = green, bold = true })
  hl('TelescopeResultsDiffDelete', { fg = red, bold = true })
  hl('TelescopeResultsDiffUntracked', { fg = gray5 })

  -- buffers (aded by spec)
  hl('TelescopeBufferActive', { fg = blue })
  hl('TelescopeBufferModified', { fg = purple })

  -- path highlighting (added by spec)
  hl('TelescopeResultsPath1', { fg = '#aaaaaa' })
  hl('TelescopeResultsPath2', { fg = '#888888' })
  hl('TelescopeResultsPath3', { fg = '#666666' })
  hl('TelescopeResultsPath4', { fg = '#444444' })
  -- }}}

  -- treesitter-context {{{
  hl('TreesitterContext', { fg = '#673f67', bg = '#201921' })
  hl('TreesitterContextLineNumber', { link = 'TreesitterContext' })
  hl('TreesitterContextBottom', { underline = true, sp = '#673f67' })
  -- added by spec
  hl('TreesitterContextJumpLine', { fg = '#cf9ebe' })
  hl('TreesitterContextVisible', { bg = '#201921' })
  hl('TreesitterContextVisibleLine', { link = 'TreesitterContextLineNumber' })
  -- }}}

end

return M

-- vim:fdm=marker
