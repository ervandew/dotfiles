return {{
  'nvim-treesitter/nvim-treesitter',
  branch = 'master', -- stable
  config = function()
    ---@diagnostic disable-next-line: missing-fields
    require('nvim-treesitter.configs').setup({
      ensure_installed = {
        'bash',
        'comment', -- to highlight FIXME, TODO, etc.
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
      matchup = {
        enable = true,
        disable_virtual_text = true,
      },
    })
  end
}}
