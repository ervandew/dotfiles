return {{
  'rcarriga/nvim-notify',
  config = function()
    require('notify').setup({ ---@diagnostic disable-line: undefined-field
      background_colour = '#000000',
    })
    ---@diagnostic disable-next-line: undefined-field
    vim.notify = require('notify').notify
  end
}}
