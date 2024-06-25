return {{
  'nvim-treesitter/nvim-treesitter-context',
  config = function()
    require('treesitter-context').setup({
      multiline_threshold = 1, -- number of lines per context
    })
  end
}}
