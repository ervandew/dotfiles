return {{
  'ervandew/vcs',
  dir = '~/projects/vim/vcs',
  config = function()
    vim.keymap.set('n', '<leader>ga', ':VcsAnnotate<cr>', { silent = true })
    vim.keymap.set('n', '<leader>gl', ':VcsLog<cr>', { silent = true })
  end
}}

-- vim:fdm=marker
