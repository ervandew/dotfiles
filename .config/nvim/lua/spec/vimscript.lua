-- local plugins
return {
  {
    dir = vim.fn.stdpath('config') .. '/vimscript',
    config = function()
      -- diff
      vim.keymap.set('ca', 'dn', 'DiffNextChange')
      vim.keymap.set('ca', 'dp', 'DiffPrevChange')

      -- ranger
      vim.keymap.set('n', '<leader>/', ':Ranger<cr>', { silent = true })
    end
  },
}
