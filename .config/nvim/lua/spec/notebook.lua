return {{
  'ervandew/notebook',
  dir = '~/projects/vim/notebook',
  init = function()
    vim.g.NotebookDir = vim.fn.expand('~/notebook/')
  end
}}
