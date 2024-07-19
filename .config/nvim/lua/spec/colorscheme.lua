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

    local white = '#cccccc'
    local gray6 = '#666666'
    local gray8 = '#888888'
    local gray9 = '#999999'

    local green = '#789978'
    local purple = '#875f87'
    local red = '#964848'
    local yellow = '#afaf5f'
    local yellow_mid = '#8f8f3f'

    local background = '#303030'

    local error= red
    local warn = yellow
    local info = '#878700'
    local hint = '#7a7a7a'

    -- override various colors
    vim.api.nvim_set_hl(0, '@boolean', { fg = purple })
    vim.api.nvim_set_hl(0, '@comment', { fg = '#525252' })
    vim.api.nvim_set_hl(0, '@comment.documentation', { link = '@comment' })
    vim.api.nvim_set_hl(0, '@comment.error', { link = '@comment.todo' })
    vim.api.nvim_set_hl(0, '@comment.todo', { fg = yellow_mid })
    vim.api.nvim_set_hl(0, '@function', { fg = white })
    vim.api.nvim_set_hl(0, '@function.builtin', { fg = gray6 })
    vim.api.nvim_set_hl(0, '@function.method', { fg = white })
    vim.api.nvim_set_hl(0, '@keyword', { fg = gray8 })
    vim.api.nvim_set_hl(0, '@markup.heading', { fg = white })
    vim.api.nvim_set_hl(0, '@number', { fg = '#624646' })
    vim.api.nvim_set_hl(0, '@string.special.url.comment', { underline = false })
    vim.api.nvim_set_hl(0, 'Comment', { link = '@comment' })
    vim.api.nvim_set_hl(0, 'ColorColumn', { bg = '#181818' })
    -- vim.api.nvim_set_hl(0, 'CursorLine', { bg = '#2c2c2c' })
    vim.api.nvim_set_hl(0, 'CurSearch', { fg = white, bg = '#638465', bold = true })
    -- using several shades lighter than CurSearch
    vim.api.nvim_set_hl(0, 'CurSearchStatus', { fg = '#a3c4a5', bg = background })
    vim.api.nvim_set_hl(0, 'DiffAdd', { fg = green, bg = background })
    vim.api.nvim_set_hl(0, 'DiffChange', { fg = yellow_mid, bg = '#232323' })
    vim.api.nvim_set_hl(0, 'DiffDelete', { fg = '#870000', bg = '#2f0000' })
    vim.api.nvim_set_hl(0, 'DiffText', { fg = yellow, bg = '#404040' })
    vim.api.nvim_set_hl(0, 'Error', { fg = error, bg = 'none' })
    vim.api.nvim_set_hl(0, 'Folded', { fg = '#5c5c5c', bg = 'none' })
    vim.api.nvim_set_hl(0, 'MatchParen', { fg = '#cf9ebe', bg = background })
    vim.api.nvim_set_hl(0, 'ModeMsg', { fg = gray9 })
    vim.api.nvim_set_hl(0, 'MoreMsg', { link = 'ModeMsg' })
    vim.api.nvim_set_hl(0, 'MsgArea', { fg = white })
    vim.api.nvim_set_hl(0, 'PmenuSel', {bg = '#333333' })
    vim.api.nvim_set_hl(0, 'Search', { fg = white, bg = '#607080' })
    -- using several shades lighter than Search
    vim.api.nvim_set_hl(0, 'SearchStatus', { fg = '#a0b0c0', bg = background, bold = true })
    vim.api.nvim_set_hl(0, 'SignColumn', { bg = 'none' })
    vim.api.nvim_set_hl(0, 'SpellBad', { fg = '#cf6171', underline = true })
    vim.api.nvim_set_hl(0, 'SpellCap', { fg = '#4186be', underline = true })
    vim.api.nvim_set_hl(0, 'SpellRare', { fg = '#cf9ebe', underline = true })
    vim.api.nvim_set_hl(0, 'SpellLocal', { fg = green, underline = true })
    vim.api.nvim_set_hl(0, 'StatusLine', { fg = white, bg = background })
    vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = '#626262', bg = background })
    vim.api.nvim_set_hl(0, 'StatusLineFF', { fg = '#c4c466', bg = background })
    vim.api.nvim_set_hl(0, 'TabLine', { fg = '#626262',  bg = background })
    vim.api.nvim_set_hl(0, 'TabLineSel', { fg = white,  bg = background })
    vim.api.nvim_set_hl(0, 'TabLineFill', { bg = background })
    vim.api.nvim_set_hl(0, 'TagListFileName', { link = 'Special' })
    vim.api.nvim_set_hl(0, 'TagListKeyword', { link = '@keyword' })
    vim.api.nvim_set_hl(0, 'TermCursor', { bg= '#acacac' })
    vim.api.nvim_set_hl(0, 'Visual', { bg = '#353535' })
    vim.api.nvim_set_hl(0, 'VisualCursor', { bg = '#d787d7' })
    vim.api.nvim_set_hl(0, 'WarningMsg', { fg = warn })

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

    -- creating these for status line
    vim.api.nvim_set_hl(0, 'DiagnosticStatusError', { fg = error, bg = background, italic = true })
    vim.api.nvim_set_hl(0, 'DiagnosticStatusHint', { fg = hint, bg = background, italic = true })
    vim.api.nvim_set_hl(0, 'DiagnosticStatusInfo', { fg = info, bg = background, italic = true })
    vim.api.nvim_set_hl(0, 'DiagnosticStatusWarn', { fg = warn, bg = background, italic = true })

    -- file type specific changes
    vim.api.nvim_set_hl(0, '@constant.git_rebase', { link = '@number' })
    vim.api.nvim_set_hl(0, '@markup.heading.gitcommit', { link = '@keyword' })
    vim.api.nvim_set_hl(0, '@string.special.url.gitcommit', { link = '@markup.link.gitcommit' })
    vim.api.nvim_set_hl(0, '@number.float.python', { link = '@number' })
    vim.api.nvim_set_hl(0, '@property.ini', { link = '@keyword' })
    vim.api.nvim_set_hl(0, '@type.ini', { link = 'Special' })

    -- lsp specific changes
    vim.api.nvim_set_hl(0, '@lsp.type.event.lua', { link = '@comment' })

    -- plugin specific changes
    vim.api.nvim_set_hl(0, 'TelescopeMatching', { fg = yellow })
    vim.api.nvim_set_hl(0, 'TelescopeResultsNormal', { fg = gray6 })
    vim.api.nvim_set_hl(0, 'TreesitterContext', { fg = purple, bg = '#453e46' })
    vim.api.nvim_set_hl(0, 'TreesitterContextLineNumber', { link = 'TreesitterContext' })
    vim.api.nvim_set_hl(0, 'TreesitterContextBottom', { underline = true })
    -- added by spec
    vim.api.nvim_set_hl(0, 'TreesitterContextVisible', { bg = '#302931' })
    vim.api.nvim_set_hl(0, 'TreesitterContextVisibleLine', { fg = '#673f67' })

    vim.api.nvim_set_hl(0, 'VcsAnnotate', { fg = gray6 })
    vim.api.nvim_set_hl(0, 'VcsAnnotateMe', { fg = purple })
    vim.api.nvim_set_hl(0, 'VcsAnnotateUncommitted', { fg = green })
    vim.api.nvim_set_hl(0, 'VcsAuthor', { fg = gray6 })
    vim.api.nvim_set_hl(0, 'VcsRevision', { link = '@number' })

    -- providing ctermfg prevents underline on DiffChange lines:
    -- bug: https://github.com/neovim/neovim/issues/9800.
    vim.api.nvim_set_hl(0, 'CursorLine', { ctermfg = 'black', bg = '#2c2c2c' })
  end,
}}
