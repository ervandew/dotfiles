return {{
  'ervandew/taglisttoo',
  dir = '~/projects/vim/taglisttoo',
  config = function()
    vim.keymap.set('n', '<leader>t', function()
      vim.fn['taglisttoo#taglist#Taglist']({ pick = 1})
    end)
  end
}}

-- vim:fdm=marker
