return {
  {
    'nvim-telescope/telescope-fzf-native.nvim',
    build = 'make',
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
  },
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local builtin = require('telescope.builtin')
      local action_state = require("telescope.actions.state")
      local actions = require('telescope.actions')
      local action_set = require('telescope.actions.set')
      local finders = require('telescope.finders')
      local pickers = require('telescope.pickers')
      local state = require('telescope.state')
      local utils = require('telescope.utils')
      local Path = require('plenary.path')

      ---@diagnostic disable-next-line: undefined-field
      local extensions = require('telescope').extensions

      local attach_mappings_file = function(prompt_bufnr) -- {{{
        --change select_default action when selecting a file
        local is_file = function()
          local entry = action_state.get_selected_entry()
          if entry.filename then
            return true
          end

          -- git_status
          if entry.value and vim.fn.filereadable(entry.value) then
            return true
          end

          -- telescope-file-browser
          if entry.Path then
            local path = entry.Path
            return Path.is_path(path) and path:is_file()
          end

          return true
        end

        ---@diagnostic disable-next-line: undefined-field
        action_set.select:replace_map({[is_file] = function()
          local picker = action_state.get_current_picker(prompt_bufnr)
          actions.close(prompt_bufnr)

          local entry = action_state.get_selected_entry()
          local selection = entry.filename or entry.value or unpack(entry)
          if picker.cwd and not entry.Path and not entry.path then
            selection = picker.cwd .. '/' .. selection
          end

          local cmd = 'split'
          if vim.fn.expand('%') == '' and
             not vim.o.modified and
             vim.fn.line('$') == 1 and
             vim.fn.getline(1) == ''
          then
            cmd = 'edit'
          end

          vim.cmd(cmd .. ' ' .. selection)

          if entry.lnum and entry.col then
            vim.fn.cursor(entry.lnum, entry.col)
          end
        end})
        return true
      end -- }}}

      require('telescope').setup({ ---@diagnostic disable-line: undefined-field {{{
        defaults = { -- {{{
          file_ignore_patterns = { '.git/' },
          sorting_strategy = 'ascending',
          layout_strategy = 'vertical',
          layout_config = {
            width = 85,
            height = .9,
            preview_height = .5,
            prompt_position = 'top',
          }, -- }}}
          path_display = function(opts, path) -- {{{
            -- first truncate the path if it doesn't fit in the window width
            if not opts.__length then
              local status = state.get_status(vim.api.nvim_get_current_buf())
              local width = vim.api.nvim_win_get_width(status.layout.results.winid)
              opts.__length = width - status.picker.selection_caret:len() - 5
            end
            if #path > opts.__length then
              path = '…' .. path:sub(#path - opts.__length)
            end

            -- highlight path elements like a gradiant so that file names and
            -- closest parents stand out the most
            local dirs = vim.split(path, utils.get_separator())
            local style = {}
            if #dirs then
              local offset = 0
              for index, dir in ipairs(dirs) do
                local hi_index = #dirs - index + 1
                local hi = hi_index <= 4 and
                  'TelescopeResultsPath' .. hi_index or
                  'TelescopeResultsPath4'
                style[#style + 1] = { { offset, offset + #dir + 1 }, hi }
                offset = offset + #dir + 1
              end
            end
            return path, style
          end, -- }}}
          mappings = { -- {{{
            i = {
              ['<tab>'] = actions.move_selection_next,
              ['<s-tab>'] = actions.move_selection_previous,
              ['<c-j>'] = actions.preview_scrolling_down,
              ['<c-k>'] = actions.preview_scrolling_up,
            },
            n = {
              ['<c-c>'] = actions.close,
              ['<space>'] = actions.toggle_selection,
              ['<tab>'] = actions.move_selection_next,
              ['<s-tab>'] = actions.move_selection_previous,
              ['<c-j>'] = actions.preview_scrolling_down,
              ['<c-k>'] = actions.preview_scrolling_up,
              -- action to change the cwd up a level
              ['<bs>'] = function(prompt_bufnr)
                local line = action_state.get_current_line()
                local cwd = action_state.get_current_picker(prompt_bufnr).cwd
                if cwd == nil then
                  cwd = vim.fn.getcwd()
                end
                builtin.find_files({
                  attach_mappings = attach_mappings_file,
                  cwd = vim.fn.fnamemodify(cwd, ':h'),
                  default_text = line,
                  hidden = true,
                })
              end,
            },
          }, -- }}}
          extensions = { -- {{{
            file_browser = {},
            fzf = {
              fuzzy = true,
              override_generic_sorter = true,
              override_file_sorter = true,
              case_mode = 'respect_case',
            }
          }, -- }}}
        },
      }) -- }}}

      vim.keymap.set('n', '<leader>fh', builtin.help_tags)

      vim.keymap.set('n', '<leader>fp', builtin.builtin)

      vim.keymap.set('n', '<leader>ff', function() -- find_files {{{
        builtin.find_files({
          attach_mappings = attach_mappings_file,
          hidden = true,
        })
      end) -- }}}

      vim.keymap.set('n', '<leader>fr', function() -- find_files (relative) {{{
        builtin.find_files({
          attach_mappings = attach_mappings_file,
          cwd = vim.fn.expand('%:h'),
          hidden = true,
        })
      end) -- }}}

      vim.keymap.set('n', '<leader>fg', function() -- live_grep {{{
        builtin.live_grep({
          attach_mappings = attach_mappings_file,
          vimgrep_arguments = {
            'rg',
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--hidden',
          }
        })
      end) -- }}}

      vim.keymap.set('n', '<leader>fb', function() -- buffers {{{
        builtin.buffers({
          attach_mappings = function(prompt_bufnr, map)
            attach_mappings_file(prompt_bufnr)
            map({ 'i', 'n' }, '<c-d>', actions.delete_buffer)
            return true
          end
        })
      end) -- }}}

      vim.keymap.set('n', '<leader>fw', function() -- window picker {{{
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
              vim.cmd(winnr .. 'winc w')
            end)
            return true
          end,
        }):find()
      end, { silent = true }) -- }}}

      vim.keymap.set('n', '<leader>gs', function() -- git_status {{{
        local make_entry = require('telescope.make_entry')
        local git_status_opts = {
          entry_maker = function(entry)
            entry = make_entry.gen_from_git_status({
              use_git_root = true,
              cwd = vim.fn.getcwd(),
            })(entry)
            -- path used in the picker, but is absolute, so swap with value
            -- which is relative.
            ---@diagnostic disable-next-line: need-check-nil
            entry.path = entry.value
            return entry
          end,
          git_icons = {
            added = '+',
            changed = '~',
            copied = '>',
            deleted = '-',
            renamed = '>',
            unmerged = '‡',
            untracked = '?',
          },
        }
        git_status_opts.attach_mappings = function(prompt_bufnr, map)
          ---@diagnostic disable-next-line: undefined-field
          actions.git_checkout:enhance {
            post = function()
              builtin.git_status(git_status_opts)
            end,
          }
          attach_mappings_file(prompt_bufnr)
          map({ 'i', 'n' }, '<tab>', actions.move_selection_next)
          map({ 'i', 'n' }, '<c-s>', actions.git_staging_toggle)
          map({ 'i', 'n' }, '<c-u>', actions.git_checkout)
          return true
        end

        builtin.git_status(git_status_opts)
      end) -- }}}

      -- extension: file_browser {{{
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension('file_browser')

      -- patch file_browser goto_parent_dir to reset the cursor position after
      -- the prompt prefix is updated
      local fb_actions = require('telescope._extensions.file_browser.actions')
      local fb_goto_parent_dir = fb_actions.goto_parent_dir
      ---@diagnostic disable-next-line: duplicate-set-field
      fb_actions.goto_parent_dir = function(prompt_bufnr)
        local current_picker = action_state.get_current_picker(prompt_bufnr)
        fb_goto_parent_dir(prompt_bufnr, false)
        local prefix = current_picker.prompt_prefix
        vim.api.nvim_win_set_cursor(current_picker.prompt_win, { 1, #prefix })
      end

      vim.keymap.set('n', '<leader>f/', function()
        extensions.file_browser.file_browser({
          attach_mappings = attach_mappings_file,
          display_stat = false,
          dir_icon = '+',
          git_status = false,
          grouped = true,
          hide_parent_dir = true,
          hidden = true,
          prompt_path = true,
        })
      end)
      -- }}}

      -- extension: fzf {{{
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension('fzf')
      -- }}}
    end
  },
}

-- vim:fdm=marker
