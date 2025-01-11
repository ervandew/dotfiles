return {{
  'slugbyte/lackluster.nvim',
  lazy = false,
  priority = 1000,
  config = function()
    require('lackluster').setup({
      tweek_background = {
        normal = 'none',
      },
    })
    vim.cmd.colorscheme('lackluster-hack')

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
    local gray11 = '#bbbbbb'

    local blue = '#708090'
    local green = '#789978'
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

    vim.api.nvim_set_hl(0, '@boolean', { fg = purple })
    vim.api.nvim_set_hl(0, '@comment', { fg = '#525252' })
    vim.api.nvim_set_hl(0, '@comment.documentation', { link = '@comment' })
    vim.api.nvim_set_hl(0, '@comment.error', { link = '@comment.todo' })
    vim.api.nvim_set_hl(0, '@comment.todo', { fg = yellow_mid })
    vim.api.nvim_set_hl(0, '@diff.minus', { fg = red })
    vim.api.nvim_set_hl(0, '@function', { fg = white })
    vim.api.nvim_set_hl(0, '@function.builtin', { fg = gray6 })
    vim.api.nvim_set_hl(0, '@function.method', { fg = white })
    vim.api.nvim_set_hl(0, '@keyword', { fg = gray8 })
    vim.api.nvim_set_hl(0, '@number', { fg = red_dark })
    vim.api.nvim_set_hl(0, '@string.special.url.comment', { underline = false })
    vim.api.nvim_set_hl(0, 'Comment', { link = '@comment' })
    vim.api.nvim_set_hl(0, 'ColorColumn', { bg = '#191919' })
    -- providing ctermfg prevents underline on DiffChange lines:
    -- bug: https://github.com/neovim/neovim/issues/9800.
    vim.api.nvim_set_hl(0, 'CursorLine', { ctermfg = 'black', bg = '#202020' })
    vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = 'white', bg = '#202020' })
    -- creating these two for SearchWrapped autocmd
    vim.api.nvim_set_hl(0, 'CurSearchMain', { fg = white, bg = '#638465' })
    vim.api.nvim_set_hl(0, 'CurSearchWrap', { fg = white, bg = '#8f5faf' })
    vim.api.nvim_set_hl(0, 'CurSearch', { link = 'CurSearchMain' })
    vim.api.nvim_set_hl(0, 'DiffAdd', { fg = green, bg = background })
    vim.api.nvim_set_hl(0, 'DiffChange', { fg = yellow_mid, bg = '#232323' })
    vim.api.nvim_set_hl(0, 'DiffDelete', { fg = '#870000', bg = '#2f0000' })
    vim.api.nvim_set_hl(0, 'DiffText', { fg = yellow, bg = '#404040' })
    vim.api.nvim_set_hl(0, 'EndOfBuffer', { fg = gray4 })
    vim.api.nvim_set_hl(0, 'Error', { fg = error, bg = 'none' })
    vim.api.nvim_set_hl(0, 'Folded', { fg = '#5c5c5c', bg = 'none' })
    vim.api.nvim_set_hl(0, 'MatchParen', { fg = '#cf9ebe', bg = background })
    vim.api.nvim_set_hl(0, 'ModeMsg', { fg = gray9 })
    vim.api.nvim_set_hl(0, 'MoreMsg', { link = 'ModeMsg' })
    vim.api.nvim_set_hl(0, 'MsgArea', { fg = white })
    vim.api.nvim_set_hl(0, 'Pmenu', { fg = '#7a7a7a', bg = gray2 })
    vim.api.nvim_set_hl(0, 'PmenuSel', { bg = gray3 })
    vim.api.nvim_set_hl(0, 'Search', { fg = white, bg = '#607080' })
    vim.api.nvim_set_hl(0, 'SignColumn', { bg = 'none' })
    vim.api.nvim_set_hl(0, 'SpellBad', { fg = '#cf6171', underline = true })
    vim.api.nvim_set_hl(0, 'SpellCap', { fg = '#4186be', underline = true })
    vim.api.nvim_set_hl(0, 'SpellRare', { fg = '#cf9ebe', underline = true })
    vim.api.nvim_set_hl(0, 'SpellLocal', { fg = green, underline = true })
    vim.api.nvim_set_hl(0, 'StatusLine', { fg = white, bg = background })
    vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = '#626262', bg = background })
    vim.api.nvim_set_hl(0, 'StatusLineFF', { fg = '#c4c466', bg = background })
    vim.api.nvim_set_hl(0, 'TabLine', { fg = '#626262',  bg = background })
    vim.api.nvim_set_hl(0, 'TabLineFill', { bg = background })
    vim.api.nvim_set_hl(0, 'TabLineSel', { fg = white,  bg = background })
    vim.api.nvim_set_hl(0, 'TabLineSelBranch', { fg = gray8, bg = background })
    vim.api.nvim_set_hl(0, 'TermCursor', { fg = gray2, bg= '#acacac'})
    vim.api.nvim_set_hl(0, 'Visual', { bg = '#353535' })
    vim.api.nvim_set_hl(0, 'VisualCursor', { bg = '#d787d7' })
    vim.api.nvim_set_hl(0, 'WarningMsg', { fg = warn })
    vim.api.nvim_set_hl(0, 'Whitespace', { fg = gray4 })

    -- file type specific changes
    vim.api.nvim_set_hl(0, '@constant.git_rebase', { fg = red_dark })
    vim.api.nvim_set_hl(0, '@markup.heading.gitcommit', { link = '@keyword' })
    vim.api.nvim_set_hl(0, '@string.special.url.gitcommit', { link = '@markup.link.gitcommit' })
    vim.api.nvim_set_hl(0, '@number.float.python', { link = '@number' })
    vim.api.nvim_set_hl(0, '@property.ini', { link = '@keyword' })
    vim.api.nvim_set_hl(0, '@type.ini', { link = 'Special' })

    -- custom status line {{{
    -- indicate if the current file has lsp errors/warnings/etc.
    vim.api.nvim_set_hl(0, 'DiagnosticStatusError', { fg = error, bg = background, italic = true })
    vim.api.nvim_set_hl(0, 'DiagnosticStatusHint', { fg = hint, bg = background, italic = true })
    vim.api.nvim_set_hl(0, 'DiagnosticStatusInfo', { fg = info, bg = background, italic = true })
    vim.api.nvim_set_hl(0, 'DiagnosticStatusWarn', { fg = warn, bg = background, italic = true })

    -- current search info in the status line
    -- using several shades lighter than CurSearch (used by custom status line)
    vim.api.nvim_set_hl(0, 'CurSearchStatus', { fg = '#a3c4a5', bg = background })
    -- using several shades lighter than Search (used by custom status line)
    vim.api.nvim_set_hl(0, 'SearchStatus', { fg = '#a0b0c0', bg = background, bold = true })
    -- }}}

    -- css {{{
    vim.api.nvim_set_hl(0, '@tag.attribute.css', { fg = gray7 })
    -- }}}

    -- lsp {{{
    vim.api.nvim_set_hl(0, '@lsp.type.event.lua', { link = '@comment' })
    vim.api.nvim_set_hl(0, 'DiagnosticHint', { fg = hint })
    vim.api.nvim_set_hl(0, 'DiagnosticError', { link = 'Error' })
    vim.api.nvim_set_hl(0, 'DiagnosticSignError', { link = 'DiagnosticError' })
    vim.api.nvim_set_hl(0, 'DiagnosticSignInfo', { fg = info })
    vim.api.nvim_set_hl(0, 'DiagnosticSignWarn', { link = 'WarningMsg' })
    vim.api.nvim_set_hl(0, 'DiagnosticUnnecessary', { link = 'DiagnosticHint' })
    vim.api.nvim_set_hl(0, 'DiagnosticUnderlineError', { fg = error, italic = true, underline = false })
    vim.api.nvim_set_hl(0, 'DiagnosticUnderlineInfo', { fg = info, italic = true, underline = false })
    vim.api.nvim_set_hl(0, 'DiagnosticUnderlineWarn', { fg = warn, italic = true, underline = false })
    vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextError', { link = 'DiagnosticError' })
    -- }}}

    -- git {{{
    vim.api.nvim_set_hl(0, 'GitAnnotate', { fg = gray6 })
    vim.api.nvim_set_hl(0, 'GitAnnotateMe', { fg = purple })
    vim.api.nvim_set_hl(0, 'GitAnnotateUncommitted', { fg = green })
    vim.api.nvim_set_hl(0, 'GitAuthor', { fg = gray9 })
    vim.api.nvim_set_hl(0, 'GitDate', { link = 'String' })
    vim.api.nvim_set_hl(0, 'GitFiles', { link = 'Comment' })
    vim.api.nvim_set_hl(0, 'GitLink', { link = 'Label' })
    vim.api.nvim_set_hl(0, 'GitLogHeader', { fg = gray9 })
    vim.api.nvim_set_hl(0, 'GitLogHeaderName', { fg = gray6 })
    vim.api.nvim_set_hl(0, 'GitLogHeaderFile', { fg = yellow_mid })
    vim.api.nvim_set_hl(0, 'GitMessage', { fg = gray11 })
    vim.api.nvim_set_hl(0, 'GitRefs', { fg = yellow_dark })
    vim.api.nvim_set_hl(0, 'GitRevision', { fg = red_dark })
    vim.api.nvim_set_hl(0, 'GitStatusAdded', { fg = green })
    vim.api.nvim_set_hl(0, 'GitStatusAhead', { fg = green })
    vim.api.nvim_set_hl(0, 'GitStatusBehind', { fg = red })
    vim.api.nvim_set_hl(0, 'GitStatusBranchLocal', { fg = green })
    vim.api.nvim_set_hl(0, 'GitStatusBranchRemote', { fg = red_dark })
    vim.api.nvim_set_hl(0, 'GitStatusComment', { link = 'Comment' })
    vim.api.nvim_set_hl(0, 'GitStatusDeleted', { fg = blue })
    vim.api.nvim_set_hl(0, 'GitStatusDeletedFile', { fg = gray5 })
    vim.api.nvim_set_hl(0, 'GitStatusDeletedStaged', { fg = green })
    vim.api.nvim_set_hl(0, 'GitStatusModified', { fg = blue })
    vim.api.nvim_set_hl(0, 'GitStatusModifiedStaged', { fg = green })
    vim.api.nvim_set_hl(0, 'GitStatusUntracked', { fg = gray8 })
    -- }}}

    -- html {{{
    vim.api.nvim_set_hl(0, 'htmlEndTag', { fg = gray5 })
    vim.api.nvim_set_hl(0, 'htmlH3', { fg = gray8 })
    vim.api.nvim_set_hl(0, 'htmlTagName', { fg = gray7 })
    -- }}}

    -- markdown {{{
    vim.api.nvim_set_hl(0, '@markup.heading', { fg = gray6, bold = true })
    vim.api.nvim_set_hl(0, '@markup.italic', { fg = gray8, italic = true })
    vim.api.nvim_set_hl(0, '@markup.link.label.markdown_inline', { fg = gray7 })
    vim.api.nvim_set_hl(0, '@markup.link.url.markdown_inline', { fg = gray4 })
    vim.api.nvim_set_hl(0, '@markup.list', { fg = gray6, bold = true })
    vim.api.nvim_set_hl(0, '@markup.quote', { fg = gray7 })
    vim.api.nvim_set_hl(0, '@markup.raw.block.markdown', { fg = gray6 })
    vim.api.nvim_set_hl(0, '@markup.raw.markdown_inline', { fg = gray6 })
    vim.api.nvim_set_hl(0, '@markup.strong', { fg = gray8, bold = true })
    -- }}}

    -- regex {{{
    vim.api.nvim_set_hl(0, 'Regex0', { fg = '#00afff', underline = true })
    vim.api.nvim_set_hl(0, 'Regex1', { fg = '#875fff', underline = true })
    vim.api.nvim_set_hl(0, 'RegexGroup0', { fg = '#5fd75f', underline = true })
    vim.api.nvim_set_hl(0, 'RegexGroup1', { fg = '#af87df', underline = true })
    -- }}}

    -- taglisttoo {{{
    vim.api.nvim_set_hl(0, 'TagListFileName', { link = 'Special' })
    vim.api.nvim_set_hl(0, 'TagListKeyword', { link = '@keyword' })
    -- }}}

    -- telescope {{{
    vim.api.nvim_set_hl(0, 'TelescopeMatching', { fg = purple })
    vim.api.nvim_set_hl(0, 'TelescopePreviewLine', { bg = background })
    vim.api.nvim_set_hl(0, 'TelescopeResultsComment', { fg = gray6 })
    vim.api.nvim_set_hl(0, 'TelescopeResultsNormal', { fg = '#aaaaaa' })
    vim.api.nvim_set_hl(0, 'TelescopeSelection', { fg = green, bg = '#202020' })

    -- git_status picker
    vim.api.nvim_set_hl(0, 'TelescopeResultsDiffAdd', { fg = green, bold = true })
    vim.api.nvim_set_hl(0, 'TelescopeResultsDiffChange', { fg = green, bold = true })
    vim.api.nvim_set_hl(0, 'TelescopeResultsDiffDelete', { fg = red, bold = true })
    vim.api.nvim_set_hl(0, 'TelescopeResultsDiffUntracked', { fg = gray5 })

    -- buffers (aded by spec)
    vim.api.nvim_set_hl(0, 'TelescopeBufferActive', { fg = blue })
    vim.api.nvim_set_hl(0, 'TelescopeBufferModified', { fg = purple })

    -- path highlighting (added by spec)
    vim.api.nvim_set_hl(0, 'TelescopeResultsPath1', { fg = '#aaaaaa' })
    vim.api.nvim_set_hl(0, 'TelescopeResultsPath2', { fg = '#888888' })
    vim.api.nvim_set_hl(0, 'TelescopeResultsPath3', { fg = '#666666' })
    vim.api.nvim_set_hl(0, 'TelescopeResultsPath4', { fg = '#444444' })
    -- }}}

    -- treesitter-context {{{
    vim.api.nvim_set_hl(0, 'TreesitterContext', { fg = '#673f67', bg = '#201921' })
    vim.api.nvim_set_hl(0, 'TreesitterContextLineNumber', { link = 'TreesitterContext' })
    vim.api.nvim_set_hl(0, 'TreesitterContextBottom', { underline = true, sp = '#673f67' })
    -- added by spec
    vim.api.nvim_set_hl(0, 'TreesitterContextVisible', { bg = '#201921' })
    vim.api.nvim_set_hl(0, 'TreesitterContextVisibleLine', { link = 'TreesitterContextLineNumber' })
    -- }}}

  end,
}}

-- vim:fdm=marker
