return {{
  'ervandew/relative',
  dir = '~/projects/vim/relative',
  config = function()
    vim.keymap.set('ca', 'er', 'EditRelative')
    vim.keymap.set('ca', 'rr', 'ReadRelative')
    vim.keymap.set('ca', 'sr', 'SplitRelative')
  end
}}

-- vim:fdm=marker
