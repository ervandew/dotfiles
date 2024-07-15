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
    local finders = require('telescope.finders')
    local pickers = require('telescope.pickers')

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
        path_display = { filename_first = { reverse_directories = true } },
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

    -- window finder {{{
    vim.keymap.set('n', '<leader>p', function()
      local bufnames = {}
      local name_to_winnr = {}
      local common_path = nil
      for winnr = 1,vim.fn.winnr('$') do
        local name = vim.fn.bufname(vim.fn.winbufnr(winnr))
        local path = vim.fn.fnamemodify(name, ':h')
        if not common_path then
          common_path = path
        else
          while common_path ~= path and common_path ~= '/' and common_path ~= '.' do
            if #path > #common_path then
              path = vim.fn.fnamemodify(path, ':h')
            else
              common_path = vim.fn.fnamemodify(common_path, ':h')
            end
          end
        end
        bufnames[winnr] = name
      end

      local names = {}
      for winnr, name in pairs(bufnames) do
        name = vim.fn.substitute(name, '^' .. common_path .. '/', '', '')
        names[#names + 1] = name
        name_to_winnr[name] = winnr
      end
      table.sort(names)
      local opts = {}
      pickers.new(opts, {
        prompt_title = 'Window Picker',
        finder = finders.new_table({results = names}),
        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = unpack(action_state.get_selected_entry())
            local winnr = name_to_winnr[selection]
            vim.print({'sel:', selection, 'winnr:', winnr})
            vim.cmd(winnr .. 'winc w')
          end)
          return true
        end,
      }):find()
    end, { silent = true })
    -- }}}
  end
}}

-- vim:fdm=marker
