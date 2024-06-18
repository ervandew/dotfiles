return {{
  'ervandew/ag',
  dir = '~/projects/vim/ag',
  config = function()
    vim.keymap.set('n', 'gf', ':Ag -g<cr>', { silent = true })
    vim.keymap.set('n', 'gF', ':Ag! -g<cr>', { silent = true })
    vim.keymap.set('n', '<leader>>', ':AgPrompt<cr>', { silent = true })
  end
}}

-- vim:fdm=marker
