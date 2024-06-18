return {{
  'ervandew/regex',
  dir = '~/projects/vim/regex',
  config = function()
    vim.api.nvim_set_hl(0, 'Regex0', { fg = '#00afff', underline = true }) -- blue
    vim.api.nvim_set_hl(0, 'Regex1', { fg = '#875fff', underline = true }) -- magenta
    vim.api.nvim_set_hl(0, 'RegexGroup0', { fg = '#5fd75f', underline = true }) -- green
    vim.api.nvim_set_hl(0, 'RegexGroup1', { fg = '#af87df', underline = true }) -- red

    vim.cmd("let g:RegexHi{0} = 'Regex0'")
    vim.cmd("let g:RegexHi{1} = 'Regex1'")
    vim.cmd("let g:RegexGroupHi{0} = 'RegexGroup0'")
    vim.cmd("let g:RegexGroupHi{1} = 'RegexGroup1'")
  end,
}}
