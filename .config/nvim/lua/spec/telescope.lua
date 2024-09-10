return {
  {
    'nvim-telescope/telescope-fzf-native.nvim',
    build = 'make',
  },
  {
    'nvim-telescope/telescope-file-browser.nvim',
  },
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local builtin = require('telescope.builtin')
      local action_state = require('telescope.actions.state')
      local actions = require('telescope.actions')
      local action_set = require('telescope.actions.set')
      local finders = require('telescope.finders')
      local pickers = require('telescope.pickers')
      local state = require('telescope.state')
      local utils = require('telescope.utils')

      ---@diagnostic disable-next-line: undefined-field
      local extensions = require('telescope').extensions

      local attach_mappings_file = function(prompt_bufnr) -- {{{
        -- change select_default action when selecting a file
        local is_file = function()
          local entry = action_state.get_selected_entry()
          if entry.filename and vim.fn.filereadable(entry.filename) == 1 then
            return true
          end

          -- git_status
          if entry.value and vim.fn.filereadable(entry.value) == 1 then
            return true
          end

          return false
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

          -- convert to a relative path if it's within our cwd
          local cwd = vim.fn.getcwd()
          if string.sub(cwd, -1) ~= '/' then
            cwd = cwd .. '/'
          end
          local index = string.find(selection, cwd, 1, true)
          if index == 1 then
            selection = string.sub(selection, #cwd + 1)
          end

          -- check if the file is already open
          local winnr = vim.fn.bufwinnr(vim.fn.bufnr('^' .. selection .. '$'))
          if winnr ~= -1 then
            vim.cmd(winnr .. 'winc w')
            vim.cmd([[ normal! m' ]]) -- update jump list

          -- open the file
          else
            local cmd = 'split'
            if vim.fn.expand('%') == '' and
               not vim.o.modified and
               vim.fn.line('$') == 1 and
               vim.fn.getline(1) == ''
            then
              cmd = 'edit'
            end
            vim.cmd(cmd .. ' ' .. selection)
          end

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
              local width = vim.api.nvim_win_get_width(status.results_win)
              -- buffers use additional 3 chars for modified/hidden status + space
              local offset = status.picker.prompt_title == 'Buffers' and 8 or 5
              opts.__length = width - status.picker.selection_caret:len() - offset
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
              ['<c-v>'] = function() vim.fn.feedkeys(vim.fn.getreg('+')) end,
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

      vim.keymap.set('n', '<leader>gb', function() -- git_branch {{{
        builtin.git_branches({
          show_remote_tracking_branches = false,
        })
      end) -- }}}

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

      -- buffers {{{
      local tab_prev = nil
      local tab_count = nil
      local buffers_tab_id_gen = 0
      local get_buffer_name = function(buffer_id)
        local name = vim.fn.bufname(buffer_id)
        if name == '' then
          name = '[No Name]'
          local winid = vim.fn.bufwinid(buffer_id)
          vim.print({'winid:', winid})
          if winid ~= -1 then
            local wininfo = vim.fn.getwininfo(winid)[1]
            vim.print({'wininfo:', wininfo})
            if wininfo.loclist == 1 then
              name = '[Location List]'
            elseif wininfo.quickfix == 1 then
              name = '[Quickfix]'
            end
          end
        end
        return name
      end
      local get_buffers = function()
        local result = {}
        local buffer_ids = vim.api.nvim_list_bufs()
        local cwd = vim.fn.getcwd()
        for _, buffer_id in ipairs(buffer_ids) do
          local name = get_buffer_name(buffer_id)
          if name ~= '[buffers]' then
            local dir = vim.fn.fnamemodify(name, ':p:h')
            if string.find(dir, cwd, 1, true) == 1 then
              dir = string.sub(dir, #cwd + 2)
            end
            result[#result + 1] = {
              bufnr = buffer_id,
              hidden = vim.fn.bufwinid(buffer_id) == -1,
              modified = vim.bo[buffer_id].modified,
              dir = dir,
              file = vim.fn.fnamemodify(name, ':p:t'),
            }
          end
        end
        return result
      end
      local function open_next_hidden_tab_buffer(current)
        local allbuffers = get_buffers()

        -- build list of buffers open in other tabs to exclude
        local tabbuffers = {}
        for tabnr = 1, vim.fn.tabpagenr('$') do
          if tabnr ~= vim.fn.tabpagenr() then
            for _, bnum in ipairs(vim.fn.tabpagebuflist(tabnr)) do
              tabbuffers[#tabbuffers + 1] = bnum
            end
          end
        end

        -- build list of buffers not open in any window, and last seen on the
        -- current tab.
        local hiddenbuffers = {}
        for _, buffer in ipairs(allbuffers) do
          local bufnr = buffer.bufnr
          if bufnr ~= current and
             not vim.list_contains(tabbuffers, bufnr) and
             vim.fn.bufwinnr(bufnr) == -1
          then
            local buffers_tab_id = vim.b[bufnr].buffers_tab_id
            if buffers_tab_id == vim.t.buffers_tab_id then
              if bufnr < current then
                local updated = { bufnr }
                vim.list_extend(updated, hiddenbuffers)
                hiddenbuffers = updated
              else
                hiddenbuffers[#hiddenbuffers] = bufnr
              end
            end
          end
        end

        -- we found a hidden buffer, so open it
        if #hiddenbuffers > 0 then
          vim.cmd('buffer ' .. hiddenbuffers[1])
          vim.cmd('doautocmd BufEnter')
          vim.cmd('doautocmd BufWinEnter')
          vim.cmd('doautocmd BufReadPost')

          return hiddenbuffers[1]
        end
        return 0
      end

      local make_entry = require('telescope.make_entry')
      local buf_displayer = require('telescope.pickers.entry_display').create({
        separator = '',
        items = {
          { width = 1 },
          { width = 2 },
          { remaining = true },
        },
      })
      local buffers_opts = {
        entry_maker = function(entry)
          -- exclude buffers open in, or last opened in, other tabs
          local tabid = vim.t.buffers_tab_id -- see "tab tracking" below
          if vim.b[entry.bufnr].buffers_tab_id ~= tabid then
            return
          end

          local filename = entry.info.name ~= '' and entry.info.name or nil
          local bufname = get_buffer_name(entry.bufnr)
          local hidden = entry.info.hidden == 1
          local modified = entry.info.changed == 1
          local make_display = function(e)
            local name, path_style = utils.transform_path({}, e.filename)
            return buf_displayer({
              {
                modified and '+' or ' ',
                'TelescopeBufferModified'
              },
              {
                hidden and 'h ' or 'a ',
                hidden and 'TelescopeResultsComment' or 'TelescopeBufferActive'
              },
              {
                name,
                function() return path_style end,
              },
            })
          end

          return make_entry.set_default_entry_mt({
            value = bufname,
            ordinal = entry.bufnr .. ' : ' .. bufname,
            display = make_display,
            bufnr = entry.bufnr,
            path = filename,
            filename = bufname,
          }, {})

        end,
      }
      buffers_opts.attach_mappings = function(prompt_bufnr, map)
        attach_mappings_file(prompt_bufnr)
        map({ 'i', 'n' }, '<c-d>', function()
          local entry = action_state.get_selected_entry()
          local bufnr = entry.bufnr

          if vim.bo[bufnr].modified then
            -- FIXME: is there a way to notify the user?
            return
          end

          -- if the buffer is currently open in a window, check if it's the last
          -- content window or not, so we can handle it accordingly
          local bufwin = vim.fn.bufwinnr(bufnr)
          local loadnext = false
          if bufwin ~= -1 then
            vim.cmd(bufwin .. 'winc w')
            -- check if there is a window above
            vim.cmd('winc k')
            -- check if there is a window below
            if vim.fn.winnr() == bufwin then
              vim.cmd('winc j')
            end
            if vim.fn.winnr() == bufwin then
              vim.cmd('above new')
              loadnext = true
            end
          end

          vim.api.nvim_buf_delete(bufnr, {})

          if loadnext then
            local delete_bufnr = vim.fn.bufnr()
            open_next_hidden_tab_buffer(bufnr)
            -- delete the old no name buffer
            vim.api.nvim_buf_delete(delete_bufnr, {})
          end
          builtin.buffers(buffers_opts)
        end)

        map({ 'i', 'n' }, '<c-o>', function()
          for _, buffer in ipairs(get_buffers()) do
            if buffer.hidden and not vim.bo[buffer.bufnr].modified then
              vim.api.nvim_buf_delete(buffer.bufnr, {})
            end
          end
          builtin.buffers(buffers_opts)
        end)
        return true
      end

      vim.keymap.set('n', '<leader>fb', function()
        builtin.buffers(buffers_opts)
      end)

      for tabnr = 1, vim.fn.tabpagenr('$') do
        local tab_id = vim.t[tabnr].buffers_tab_id
        if not tab_id then
          buffers_tab_id_gen = buffers_tab_id_gen + 1
          local buffers_tab_id = buffers_tab_id_gen
          vim.t[tabnr].buffers_tab_id = buffers_tab_id
          for _, bufnr in ipairs(vim.fn.tabpagebuflist(tabnr)) do
            local btab_id = vim.b[bufnr].buffers_tab_id
            if not btab_id then
              vim.b[bufnr].buffers_tab_id = buffers_tab_id
            end
          end
        end
      end

      local augroup vim.api.nvim_create_augroup('buffers_tab_tracking', {})
      vim.api.nvim_create_autocmd({ 'BufWinEnter', 'BufWinLeave' }, {
        group = augroup,
        pattern = '*',
        callback = function()
          -- track the last tab a buffer was loaded in
          local bufnr = vim.fn.bufnr('%')

          if not vim.api.nvim_buf_is_loaded(bufnr) and vim.b.buffers_tab_id then
            vim.b.buffers_tab_id = nil
          end

          -- check if the buffer is loaded in another tab
          local other_tab = nil
          for tabnr = 1, vim.fn.tabpagenr('$') do
            if tabnr ~= vim.fn.tabpagenr() then
              local buflist = vim.fn.tabpagebuflist(tabnr)
              if vim.list_contains(buflist, bufnr) then
                other_tab = tabnr
                break
              end
            end
          end

          if not vim.b.buffers_tab_id and not other_tab then
            vim.b.buffers_tab_id = vim.t.buffers_tab_id
          end
        end
      })
      vim.api.nvim_create_autocmd('TabEnter', {
        group = augroup,
        pattern = '*',
        callback = function()
          if tab_count and tab_count > vim.fn.tabpagenr('$') then
            -- delete any buffers associated with the closed tab
            for _, buffer in ipairs(get_buffers()) do
              local buffers_tab_id = vim.b[buffer.bufnr].buffers_tab_id
              if buffers_tab_id == tab_prev and buffer.hidden then
                vim.api.nvim_buf_delete(buffer.bufnr, {})
              end
            end
          end
        end
      })
      vim.api.nvim_create_autocmd('TabLeave', {
        group = augroup,
        pattern = '*',
        callback = function()
          tab_prev = vim.t.buffers_tab_id
          tab_count = vim.fn.tabpagenr('$')
        end
      })

      vim.keymap.set('ca', 'bd', 'BufferDelete')
      vim.api.nvim_create_user_command('BufferDelete', function(opts)
        local bufnr = vim.api.nvim_get_current_buf()
        if vim.bo[bufnr].modified and not opts.bang then
          local msg = 'Buffer is modified. Write the buffer or add ! to delete'
          vim.api.nvim_echo({{ msg, 'Error' }}, false, {})
          return
        end

        local windows = 0
        for winnr = 1, vim.fn.winnr('$') do
          local winid = vim.fn.win_getid(winnr)
          -- exclude any windows with a fixed height or width, as these are most
          -- likely some sort of tool window (tag list, etc)
          if not (vim.w[winid].winfixheight or vim.w[winid].winfixwidth) then
            windows = windows + 1
          end
        end

        if windows == 1 then
          vim.cmd('new')
          -- try loading a hidden buffer from the current tab
          open_next_hidden_tab_buffer(bufnr)
        end

        vim.api.nvim_buf_delete(bufnr, { force = opts.bang })
        vim.cmd('redraw') -- force tabline to update
      end, { bang = true, nargs = 0 })
    -- }}}

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
