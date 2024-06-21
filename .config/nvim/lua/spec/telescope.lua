return {{
  'nvim-telescope/telescope.nvim',
  branch = '0.1.x',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<leader>ff', builtin.find_files)
    vim.keymap.set('n', '<leader>fb', builtin.buffers)
    vim.keymap.set('n', '<leader>fg', builtin.live_grep)
    vim.keymap.set('n', '<leader>fp', builtin.builtin)
    vim.keymap.set('n', '<leader>fr', function()
      builtin.find_files({
        cwd = vim.fn.expand('%:h'),
        opts = {},
      })
    end)

    local action_state = require("telescope.actions.state")
    local actions = require('telescope.actions')
    local cd_up = function(prompt_bufnr)
      local line = action_state.get_current_line()
      local cwd = action_state.get_current_picker(prompt_bufnr).cwd
      if cwd == nil then
        cwd = vim.fn.getcwd()
      end
      builtin.find_files({
        cwd = vim.fn.fnamemodify(cwd, ':h'),
        default_text = line,
      })
    end
    require('telescope').setup({ ---@diagnostic disable-line: undefined-field
      defaults = {
        sorting_strategy = 'ascending',
        layout_strategy = 'vertical',
        layout_config = {
          width = 85,
          height = .9,
          preview_height = .5,
          prompt_position = 'top',
        },
        path_display = { 'smart' },
        mappings = {
          i = {
            ['<tab>'] = actions.move_selection_next,
            ['<s-tab>'] = actions.move_selection_previous,
            ['<c-s>'] = actions.select_horizontal,
          },
          n = {
            ['<c-c>'] = actions.close,
            ['<space>'] = actions.toggle_selection,
            ['<tab>'] = actions.move_selection_next,
            ['<s-tab>'] = actions.move_selection_previous,
            ['<c-s>'] = actions.select_horizontal,
            ['<bs>'] = cd_up,
          },
        }
      },
    })
  end
}}
