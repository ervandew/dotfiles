return {{
  'folke/flash.nvim',
  event = 'VeryLazy',
  keys = {
    {
      's',
      mode = 'n',
      function()
        ---@diagnostic disable-next-line: undefined-field
        require('flash').jump()
      end
    },
  },
  opts = {
    -- highlight = { backdrop = false },
    modes = {
      -- disable the f/t/etc keys
      char = { enabled = false },
    },
    prompt = {
      prefix = { { '> ', 'FlashPromptIcon' } },
    },
  }
}}
