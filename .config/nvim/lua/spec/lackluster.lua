return {{
  'slugbyte/lackluster.nvim',
  lazy = false,
  priority = 1000,
  config = function()
    local lackluster = require("lackluster")
    lackluster.setup({
      tweek_background = {
        normal = 'none',
      },
    })

    vim.cmd.colorscheme('lackluster-hack')

    -- override some of lackluster's colors
    vim.api.nvim_set_hl(0, '@boolean', { fg = '#875f87' })
    vim.api.nvim_set_hl(0, '@comment', { fg = '#525252' })
    vim.api.nvim_set_hl(0, '@comment.documentation', { link = '@comment' })
    vim.api.nvim_set_hl(0, '@comment.error', { link = '@comment.todo' })
    vim.api.nvim_set_hl(0, '@comment.todo', { fg = '#8f8f3f' })
    vim.api.nvim_set_hl(0, '@function', { fg = '#cccccc' })
    vim.api.nvim_set_hl(0, '@function.builtin', { fg = '#666666' })
    vim.api.nvim_set_hl(0, '@function.method', { fg = '#cccccc' })
    vim.api.nvim_set_hl(0, '@markup.heading', { fg = '#cccccc' })
    vim.api.nvim_set_hl(0, '@number', { fg = '#624646' })
    vim.api.nvim_set_hl(0, 'Comment', { link = '@comment' })
    vim.api.nvim_set_hl(0, 'ColorColumn', { bg = '#181818' })
    vim.api.nvim_set_hl(0, 'CursorLine', { bg = '#2c2c2c' })
    vim.api.nvim_set_hl(0, 'CurSearch', { fg = '#cccccc', bg = '#638465' })
    vim.api.nvim_set_hl(0, 'DiffAdd', { fg = '#5f875f', bg = '#303030' })
    vim.api.nvim_set_hl(0, 'DiffDelete', { fg = '#870000', bg = '#2f0000' })
    vim.api.nvim_set_hl(0, 'DiffText', { fg = '#afaf5f', bg = '#404040' })
    vim.api.nvim_set_hl(0, 'Error', { fg = '#964848' })
    vim.api.nvim_set_hl(0, 'Folded', { fg = '#5c5c5c', bg = 'none' })
    vim.api.nvim_set_hl(0, 'MatchParen', { fg = '#cf9ebe', bg = '#303030' })
    vim.api.nvim_set_hl(0, 'MatchParenOffscreen', { bg = '#453e46' })
    vim.api.nvim_set_hl(0, 'MsgArea', { fg = '#cccccc' })
    vim.api.nvim_set_hl(0, 'PmenuSel', {bg = '#333333' })
    vim.api.nvim_set_hl(0, 'Search', { fg = '#cccccc', bg = '#607080' })
    vim.api.nvim_set_hl(0, 'SignColumn', { bg = 'none' })
    vim.api.nvim_set_hl(0, 'SpellBad', { fg = '#cf6171', underline = true })
    vim.api.nvim_set_hl(0, 'SpellCap', { fg = '#4186be', underline = true })
    vim.api.nvim_set_hl(0, 'SpellRare', { fg = '#cf9ebe', underline = true })
    vim.api.nvim_set_hl(0, 'SpellLocal', { fg = '#5f875f', underline = true })
    vim.api.nvim_set_hl(0, 'StatusLine', { fg = '#cccccc', bg = '#303030' })
    vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = '#626262', bg = '#303030' })
    vim.api.nvim_set_hl(0, 'StatusLineFF', { fg = '#c4c466', bg = '#303030' })
    vim.api.nvim_set_hl(0, 'TabLine', { fg='#626262',  bg = '#303030' })
    vim.api.nvim_set_hl(0, 'TabLineSel', { fg='#cccccc',  bg = '#303030' })
    vim.api.nvim_set_hl(0, 'TabLineFill', { bg = '#303030' })
    vim.api.nvim_set_hl(0, 'TagListFileName', { link = 'Special' })
    vim.api.nvim_set_hl(0, 'TagListKeyword', { link = '@keyword' })
    vim.api.nvim_set_hl(0, 'TermCursor', { bg= '#ac7d00' })
    vim.api.nvim_set_hl(0, 'VcsAnnotate', { link = 'Special' })
    vim.api.nvim_set_hl(0, 'Visual', { bg = '#353535' })
    vim.api.nvim_set_hl(0, 'WarningMsg', { fg = '#afaf5f' })

    vim.api.nvim_set_hl(0, 'DiagnosticHint', { fg = '#7a7a7a' })
    vim.api.nvim_set_hl(0, 'DiagnosticError', { link = 'Error' })
    vim.api.nvim_set_hl(0, 'DiagnosticSignError', { link = 'DiagnosticError' })
    vim.api.nvim_set_hl(0, 'DiagnosticSignWarn', { link = 'WarningMsg' })
    vim.api.nvim_set_hl(0, 'DiagnosticUnnecessary', { link = 'DiagnosticHint' })
    vim.api.nvim_set_hl(0, 'DiagnosticUnderlineError', { fg = '#875f5f', italic = true, underline = false })
    vim.api.nvim_set_hl(0, 'DiagnosticUnderlineInfo', { fg = '#878700', italic = true, underline = false })
    vim.api.nvim_set_hl(0, 'DiagnosticUnderlineWarn', { fg = '#878700', italic = true, underline = false })
    vim.api.nvim_set_hl(0, 'DiagnosticVirtualTextError', { link = 'DiagnosticError' })

    -- file type specific changes
    vim.api.nvim_set_hl(0, '@constant.git_rebase', { link = '@number' })
    vim.api.nvim_set_hl(0, '@markup.heading.gitcommit', { fg = '#888888' })
    vim.api.nvim_set_hl(0, '@string.special.url.gitcommit', { link = '@markup.link.gitcommit' })
    vim.api.nvim_set_hl(0, '@number.float.python', { link = '@number' })

    -- lsp specific changes
    vim.api.nvim_set_hl(0, '@lsp.type.event.lua', { link = '@comment' })

    -- plugin specific changes
    vim.api.nvim_set_hl(0, 'TelescopeMatching', { fg = '#afaf5f' })
    vim.api.nvim_set_hl(0, 'TelescopeResultsNormal', { fg = '#666666' })
  end,
}}
