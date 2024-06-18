return {{
  'ervandew/maximize',
  dir = '~/projects/vim/maximize',
  config = function()
    vim.keymap.set('n', '<space><space>', ':MaximizeWindow<cr>', { silent = true })
  end
}}

-- vim:fdm=marker
