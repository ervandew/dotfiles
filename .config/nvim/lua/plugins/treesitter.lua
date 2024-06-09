return {{
  'nvim-treesitter/nvim-treesitter',
  config = function()
    require('nvim-treesitter.configs').setup({
      ensure_installed = {
        'bash',
        'javascript',
        'lua',
        'query',
        'python',
        'rst',
        'vim',
        'vimdoc',
      },
      auto_install = true,
      highlight = { enable = true },
      matchup = { enable = true },
    })
  end
}}
