return {{
  'ervandew/buffers',
  dir = '~/projects/vim/buffers',
  config = function()
    vim.g.BuffersDeleteOnTabClose = 1
    vim.keymap.set('n', '<leader>b', ':BuffersToggle<cr>', { silent = true })
    -- replace :bd with version which won't close the current tab if deleting the
    -- last buffer on that tab
    vim.keymap.set('ca', 'bd', 'BufferDelete')
  end
}}

-- vim:fdm=marker
