return {{
  'ervandew/notebook',
  dir = '~/projects/vim/notebook',
  config = function()
    vim.g.NotebookDir = vim.fn.expand('~/notebook/')
  end
}}

-- vim:fdm=marker
