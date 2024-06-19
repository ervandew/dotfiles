return {{
  'ervandew/lookup',
  dir = '~/projects/vim/lookup',
  config = function()
    vim.g.LookupRuntimePath = 'all'
    vim.g.LookupSingleResultAction = 'split'
    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'help', 'lua', 'vim' },
      callback = function()
        vim.keymap.set('n', '<cr>', ':Lookup<cr>', { buffer = true, silent = true })
      end
    })
  end
}}
