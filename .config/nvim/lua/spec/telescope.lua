return {
  {
    'nvim-telescope/telescope-fzf-native.nvim',
    build = 'make',
  },
  {
    'nvim-telescope/telescope-file-browser.nvim',
  },
  {
    'nvim-telescope/telescope-live-grep-args.nvim',
    version = "^1.1.0",
  },
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local builtin = require('telescope.builtin')
      local conf = require('telescope.config').values
      local action_state = require('telescope.actions.state')
      local actions = require('telescope.actions')
      local action_set = require('telescope.actions.set')
      local finders = require('telescope.finders')
      local pickers = require('telescope.pickers')
      local state = require('telescope.state')
      local utils = require('telescope.utils')
      local esc = vim.api.nvim_replace_termcodes('<esc>', true, false, true)

      ---@diagnostic disable-next-line: undefined-field
      local extensions = require('telescope').extensions

      local attach_mappings_file = function(prompt_bufnr) -- {{{
        -- change select_default action when selecting a file
        local is_file = function()
          local entry = action_state.get_selected_entry()
          if entry then
            if entry.filename and vim.fn.filereadable(entry.filename) == 1 then
              return true
            end

            -- git_status
            if entry.value and vim.fn.filereadable(entry.value) == 1 then
              return true
            end
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

          -- convert to a relative path if possible
          selection = vim.fn.fnamemodify(selection, ':.')

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

      local current_prompt_text = function() -- {{{
        for _, bufnr in ipairs(vim.fn.tabpagebuflist()) do
          if vim.bo[bufnr].filetype == 'TelescopePrompt' then
            return action_state.get_current_picker(bufnr):_get_prompt()
          end
        end
        return ''
      end -- }}}

      local search_path = function() -- {{{
        local cwd = vim.fn.getcwd()

        -- if the current file isn't within our cwd, then attempt to find a
        -- suitable root dir (git repo, or just the parent directory)
        local path = vim.fn.expand('%:p:h')
        if not path:match('^' .. cwd:gsub('%-', '%%-')) then
          local found = vim.fn.finddir('.git', path .. ';')
          if found ~= '' then
            cwd = vim.fn.fnamemodify(found, ':p:h:h')
          else
            cwd = path
          end
        end

        local cwd_display = vim.fn.fnamemodify(cwd, ':t')
        return cwd, cwd_display
      end -- }}}

      require('telescope').setup({ ---@diagnostic disable-line: undefined-field {{{
        defaults = { -- {{{
          file_ignore_patterns = { '%.git/' },
          sorting_strategy = 'ascending',
          layout_strategy = 'vertical',
          layout_config = {
            width = 85,
            height = .9,
            preview_height = .5,
            prompt_position = 'top',
          },
          path_display = function(opts, path) -- {{{
            -- make the path relative if possible
            path = vim.fn.fnamemodify(path, ':.')

            -- truncate the path if it doesn't fit in the window width
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
              ['<a-bs>'] = function()
                vim.fn.feedkeys(
                  vim.api.nvim_replace_termcodes('<c-w>', true, false, true)
                )
              end,
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

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'TelescopeResults',
        callback = function() vim.opt_local.scrolloff = 5 end,
      })
      vim.api.nvim_create_autocmd('User', {
        pattern = 'TelescopePreviewerLoaded',
        callback = function() vim.wo.number = true end,
      })

      vim.keymap.set('n', 'z=', builtin.spell_suggest)

      vim.keymap.set('n', '<leader>fh', builtin.help_tags)

      vim.keymap.set('n', '<leader>fp', builtin.builtin)

      vim.keymap.set('n', '<leader>ff', function() -- find_files {{{
        local cwd, cwd_display = search_path()
        builtin.find_files({
          attach_mappings = function(prompt_bufnr, map)
            attach_mappings_file(prompt_bufnr)
            map('i', '<c-f>', function() -- switch to live_grep
              vim.api.nvim_feedkeys(esc .. vim.g.mapleader .. 'fg', 'm', false)
            end)
            return true
          end,
          cwd = cwd,
          hidden = true,
          default_text = current_prompt_text(),
          prompt_title = 'Find Files: ' .. cwd_display,
        })
      end)
      -- when using :S command of my open.lua, allow ctrl-f to switch to fuzzy
      -- file finder, with the :S command arg as the initial search text
      vim.keymap.set('c', '<c-f>', function()
        local cmd = vim.fn.getcmdline()
        local result = string.find(cmd, '^S%s')
        if result then
          local default_text = string.gsub(cmd, '^S%s+', '')
          -- cancel command mode
          vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes('<c-c>', true, false, true),
            'n',
            false
          )
          -- open telescope after feedkeys above runs
          vim.schedule(function()
            builtin.find_files({
              attach_mappings = attach_mappings_file,
              default_text = default_text,
              hidden = true,
            })
          end)
        else
          -- fallback to default behavior (open command history window)
          vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes('<c-f>', true, false, true),
            'n',
            false
          )
        end
      end)
      -- }}}

      vim.keymap.set('n', '<leader>ft', function() -- treesitter {{{
        local ts_results = function(lang, parser) -- {{{
          local node_name = function(results, node, start_lnum, end_lnum)
            local name = vim.treesitter.get_node_text(node, 0, {})
            for i = #results, 1, -1 do
              local adj = results[i]
              if adj.start_lnum <= start_lnum and
                 adj.end_lnum >= end_lnum
              then
                name = adj.name .. '.' .. name
                break
              end
            end
            return name
          end

          local current
          local current_index
          local results = {}
          local lnum = vim.fn.line('.') - 1
          local path = vim.fn.expand('%:p')
          local root = parser:parse(true)[1]:root()
          local query = vim.treesitter.query.get(lang, 'telescope-treesitter')
          if not query then
            vim.print('No query file found for: ' .. lang)
            return
          end

          ---@diagnostic disable-next-line: missing-parameter
          for _, node, _, _ in query:iter_captures(root, 0) do
            -- we query for names, so grab the parent to get the range of the
            -- block
            local parent = node:parent()

            -- edge case for markdown where we need to go up 2 levels to get to
            -- the section node
            if lang == 'markdown' and parent then
              parent = parent:parent()
            end

            if parent then
              local start_lnum, start_col = parent:start()
              local end_lnum, end_col = parent:end_()
              local name = node_name(results, node, start_lnum, end_lnum)

              -- set the current name if we are within this block, but remove
              -- the last part if we are in the child of another node (prevent
              -- our initial results from being just the current node, and
              -- hopefully provide a list of nodes in the outer context)
              if start_lnum <= lnum and lnum <= end_lnum then
                current = name
                current_index = #results + 1
                if #results ~= 0 and string.match(name, '%.') then
                  local parent_name = string.match(name, '(.*)%.')
                  local prev_name = results[#results].name
                  if prev_name == parent_name or
                     string.match(prev_name, parent_name .. '%.')
                  then
                    current = parent_name .. '.'
                  end
                end
              end

              results[#results + 1] = {
                path = path,
                name = name,
                start_lnum = start_lnum + 1,
                start_col = start_col + 1,
                end_lnum = end_lnum + 1,
                end_col = end_col + 1,
              }
            end
          end

          -- if 'current' is just 1 node, then don't use it so we aren't
          -- presenting just a single result that will probably need to be
          -- removed to see broader results
          if current and not string.match(current, '%.$') then
            if #results == current_index then
              current = nil
            elseif #results > current_index and
               not string.match(results[current_index + 1].name, current .. '%.')
            then
              current = nil
            end
          end

          return { current = current, results = results }
        end -- }}}

        local regex_results = function() -- {{{
          local patterns_file = vim.fn.findfile(
            'queries/' .. vim.o.ft .. '/telescope-treesitter.re',
            vim.o.rtp
          )
          if patterns_file == '' then
            vim.print('No patterns file found for: ' .. vim.o.ft)
            return
          end

          local results = {}
          local path = vim.fn.expand('%:p')
          local patterns = vim.fn.readfile(patterns_file)
          for _, pattern in ipairs(patterns) do
            if string.sub(pattern, 1, 1) ~= ';' then
              local type = string.match(pattern, '(.*):.*')
              pattern = string.match(pattern, '.*:(.*)')
              pattern = vim.fn.escape(pattern, '"')
              local cmd =
                'cat ' .. path .. ' | ' ..
                'perl -ne "s|' .. pattern .. '|$.:\\1| && print"'
              for _, result in ipairs(vim.fn.systemlist(cmd)) do
                local lnum = tonumber(string.match(result, '(%d+):'))
                local name = string.match(result, '%d+:(.*)')
                results[#results + 1] = {
                  path = path,
                  name = type .. ':' .. name,
                  start_lnum = lnum,
                  start_col = 1,
                }
              end
            end
          end
          return { results = results }
        end -- }}}

        local sep
        local results
        local lang = vim.treesitter.language.get_lang(vim.o.ft)
        local ok, parser = pcall(vim.treesitter.get_parser, 0, lang)
        if ok then
          sep = '.'
          results = ts_results(lang, parser)
        elseif vim.o.ft ~= '' then
          sep = ':'
          results = regex_results()
        end

        if not results then
          return
        end

        local opts = {}
        local entries = results.results
        table.sort(entries, function(e1, e2)
          return e1.name:lower() < e2.name:lower()
        end)
        pickers.new(opts, {
          default_text = results.current,
          prompt_title = 'Treesitter Picker',
          finder = finders.new_table({
            results = entries,
            entry_maker = function(entry)
              -- highlight elements like a gradiant so the most significant
              -- part stands out
              local parts = vim.split(entry.name, sep, { plain = true })
              local style = {}
              if #parts then
                local offset = 0
                for index, part in ipairs(parts) do
                  local hi_index = #parts - index + 1
                  local hi = hi_index <= 4 and
                    'TelescopeResultsPath' .. hi_index or
                    'TelescopeResultsPath4'
                  style[#style + 1] = { { offset, offset + #part + 1 }, hi }
                  offset = offset + #part + 1
                end
              end

              return {
                path = entry.path,
                display = function()
                  return entry.name, style
                end,
                ordinal = entry.name,
                lnum = entry.start_lnum,
                col = entry.start_col,
              }
            end,
          }),

          attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              vim.fn.cursor(selection.lnum, selection.col + 1)
              -- open folds (z0), center the cursor line (zz)
              vim.cmd('silent! normal! zOzz')
            end)
            map('i', '<c-f>', function() -- switch to find_files
              vim.api.nvim_feedkeys(esc .. vim.g.mapleader .. 'ff', 'm', false)
            end)
            return true
          end,
          previewer = conf.grep_previewer(opts),
          sorter = conf.generic_sorter(opts),
        }):find()
      end, { silent = true }) -- }}}

      vim.keymap.set('n', '<leader>fq', function() -- quickfix {{{
        builtin.quickfix({
          attach_mappings = attach_mappings_file,
        })
      end) -- }}}

      vim.keymap.set('n', '<leader>fw', function() -- window {{{
        local bufnames = {}
        local name_to_winnr = {}
        local common_path = nil
        for winnr = 1,vim.fn.winnr('$') do
          local winid = vim.fn.win_getid(winnr)
          if not vim.api.nvim_win_get_config(winid).zindex then
            local name = vim.fn.bufname(vim.fn.winbufnr(winnr))
            local path = vim.fn.fnamemodify(name, ':h')
            if not common_path then
              common_path = path
            else
              while common_path ~= path and
                    common_path ~= '/' and
                    common_path ~= '.'
              do
                if #path > #common_path then
                  path = vim.fn.fnamemodify(path, ':h')
                else
                  common_path = vim.fn.fnamemodify(common_path, ':h')
                end
              end
            end
            bufnames[winnr] = name
          end
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
          sorter = conf.generic_sorter(opts),
        }):find()
      end, { silent = true }) -- }}}

      vim.keymap.set('n', '<leader>gb', function() -- git_branch {{{
        builtin.git_branches({
          show_remote_tracking_branches = false,
        })
      end) -- }}}

      -- buffers {{{
      local tab_prev = nil
      local tab_count = 1
      local buffers_tab_id_gen = 0
      local get_buffer_name = function(buffer_id)
        local name = vim.fn.bufname(buffer_id)
        if name == '' then
          name = '[No Name]'
          local winid = vim.fn.bufwinid(buffer_id)
          if winid ~= -1 then
            local wininfo = vim.fn.getwininfo(winid)[1]
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
        for _, buffer_id in ipairs(buffer_ids) do
          if vim.api.nvim_buf_is_loaded(buffer_id) then
            local name = get_buffer_name(buffer_id)
            local dir = vim.fn.fnamemodify(name, ':p:h')
            result[#result + 1] = {
              bufnr = buffer_id,
              hidden = vim.fn.bufwinid(buffer_id) == -1,
              modified = vim.bo[buffer_id].modified,
              dir = vim.fn.fnamemodify(dir, ':.'),
              file = vim.fn.fnamemodify(name, ':p:t'),
            }
          end
        end
        return result
      end
      local function next_hidden_tab_buffer(current)
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
        local hiddenbuffers_noname = {}
        for _, buffer in ipairs(allbuffers) do
          local bufnr = buffer.bufnr
          if bufnr ~= current and
             not vim.list_contains(tabbuffers, bufnr) and
             vim.fn.bufwinnr(bufnr) == -1 and
             vim.bo[bufnr].ft ~= 'qf'
          then
            local buffers_tab_id = vim.b[bufnr].buffers_tab_id
            if tab_count == 1 or buffers_tab_id == vim.t.buffers_tab_id then
              local noname = vim.fn.bufname(bufnr) == ''
              if bufnr < current then
                local updated = { bufnr }
                if noname then
                  vim.list_extend(updated, hiddenbuffers_noname)
                  hiddenbuffers_noname = updated
                else
                  vim.list_extend(updated, hiddenbuffers)
                  hiddenbuffers = updated
                end
              elseif noname then
                hiddenbuffers_noname[#hiddenbuffers_noname + 1] = bufnr
              else
                hiddenbuffers[#hiddenbuffers + 1] = bufnr
              end
            end
          end
        end

        local next_bufnr
        if #hiddenbuffers > 0 then
          next_bufnr = hiddenbuffers[1]
        elseif #hiddenbuffers_noname > 0 then
          next_bufnr = hiddenbuffers_noname[1]
        end
        return next_bufnr
      end

      local function open_next_hidden_tab_buffer(current, next_bufnr)
        next_bufnr = next_bufnr or next_hidden_tab_buffer(current)
        if next_bufnr then
          vim.cmd('buffer ' .. next_bufnr)
          vim.cmd('doautocmd BufEnter')
          vim.cmd('doautocmd BufWinEnter')
          vim.cmd('doautocmd BufReadPost')
        end
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
        show_all_buffers = false, -- hide unloaded buffers
        entry_maker = function(entry)
          -- exclude buffers open in, or last opened in, other tabs
          local tabid = vim.t.buffers_tab_id -- see "tab tracking" below
          if tab_count > 1 and vim.b[entry.bufnr].buffers_tab_id ~= tabid then
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

          vim.api.nvim_buf_delete(bufnr, { unload = true })

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
              vim.api.nvim_buf_delete(buffer.bufnr, { unload = true })
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
          if tab_count > vim.fn.tabpagenr('$') then
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
          -- exclude any floating windows, quickfix windows, or windows with a
          -- fixed height or width, as these are most likely some sort of tool
          -- window (tag list, etc)
          if not (
            vim.w[winid].winfixheight or
            vim.w[winid].winfixwidth or
            vim.api.nvim_win_get_config(winid).zindex or
            vim.fn.getwininfo(winid)[1].quickfix == 1
          ) then
            windows = windows + 1
          end
        end

        if windows == 1 then
          -- try loading a hidden buffer from the current tab
          local next_bufnr = next_hidden_tab_buffer(bufnr)
          if next_bufnr then
            open_next_hidden_tab_buffer(nil, next_bufnr)
          else
            vim.cmd('new')
          end
        end

        -- NOTE: just unload the buffer so we don't delete buffers referenced
        -- by the quickfix list, which causes a "Buffer <n> not found" error
        -- attempting to jump to the entry.
        vim.api.nvim_buf_delete(bufnr, { force = opts.bang, unload = true })
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
          no_ignore = true,
          prompt_path = true,
        })
      end)
      -- }}}

      -- extension: fzf {{{
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension('fzf')
      -- }}}

      -- extension: live-grep-args {{{
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension('live_grep_args')
      vim.keymap.set('n', '<leader>fg', function()
        -- check if the cursor is on a search match, and if so, pre-populate
        -- telescope with that pattern
        local default_text = ''
        local pattern = vim.fn.getreg('/')
        local line = vim.fn.getline('.')
        local col = vim.fn.col('.')
        local matches = {}
        local start = 0
        while true do
          local match = vim.fn.matchstrpos(line, pattern, start)
          if match[3] == -1 then
            break
          end
          matches[#matches + 1] = {match[2], match[3]}
          start = match[3]
        end
        for _, match in ipairs(matches) do
          if col > match[1] and col <= match[2] then
            default_text = pattern
            break
          end
        end

        if default_text == '' then
          default_text = current_prompt_text()
        end

        local cwd, cwd_display = search_path()
        local lga_actions = require('telescope-live-grep-args.actions')
        ---@diagnostic disable-next-line: undefined-field
        require('telescope').extensions.live_grep_args.live_grep_args({
          attach_mappings = function(prompt_bufnr, map)
            attach_mappings_file(prompt_bufnr)
            map('i', '<c-f>', function() -- switch to find_files
              vim.api.nvim_feedkeys(esc .. vim.g.mapleader .. 'ff', 'm', false)
            end)
            return true
          end,
          cwd = cwd,
          default_text = default_text,
          prompt_title = 'Live Grep: ' .. cwd_display,
          mappings = {
            i = {
              -- Examples of common args to add to the pattern:
              --   limit file types:  -t py
              --   limit to dir glob: -g **/path/**
              ['<c-k>'] = lga_actions.quote_prompt(),
              -- Send all results to the quickfix list and jump to first result
              ['<c-q>'] = function(prompt_bufnr)
                actions.send_to_qflist(prompt_bufnr)
                vim.cmd('cfirst')
              end,
            }
          },
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

      vim.api.nvim_create_user_command('A', function(cmd_opts) -- archive {{{
        local archive = cmd_opts.args

        vim.fn.system('which atool')
        if vim.v.shell_error ~= 0 then
          vim.print('atool not found in your path')
          return
        end

        local lines = vim.fn.systemlist(
          'atool --list "' .. archive .. '"'
        )
        if vim.v.shell_error ~= 0 then
          for _, line in ipairs(lines) do
            vim.print(line)
          end
          return
        end

        local results = {}
        local prefix
        for _, line in ipairs(lines) do
          -- match lines that have a time, but exclude lone directory entries
          if string.match(line, '%d:%d') and
             not string.match(line, '/$')
          then
            -- try to detect if the entry starts with file permissions, and
            -- if so remove them
            if string.match(line, '^-') then
              line = vim.fn.substitute(
                line,
                '.\\{-}\\S\\(\\s\\+\\d.*\\)',
                '\\1',
                ''
              )
            end

            local path = vim.fn.substitute(
              line,
              '.\\{-}\\s\\+\\d\\+:\\d\\+\\s\\+',
              '',
              ''
            )
            local line_prefix = string.gsub(line, '^(%s*).*', '%1')
            if not prefix or #line_prefix < #prefix then
              prefix = line_prefix
            end
            results[#results + 1] = { path = path, display = line }
          end
        end

        -- remove unnecessary leading spaces if any
        if prefix then
          for _, result in ipairs(results) do
            result.display = string.gsub(result.display, prefix, '')
          end
        end

        local term_previewer = require('telescope.previewers.term_previewer')
        local opts = {}
        local archive_name = vim.fn.fnamemodify(archive, ':t')
        pickers.new(opts, {
          prompt_title = 'Archive: ' .. archive_name,
          finder = finders.new_table({
            results = results,
            entry_maker = function(entry)
              return {
                display = entry.display,
                ordinal = entry.path,
                path = entry.path
              }
            end,
          }),
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              local bufname = archive_name .. ':' .. selection.path
              vim.cmd('new | r! ' ..
                'atool' ..
                '  --cat' ..
                '  "' .. archive .. '"' ..
                '  "' .. selection.path .. '"')
              -- delete empty first line and file name on second that atool
              -- prints
              vim.cmd('1,2d')
              vim.cmd('file ' .. vim.fn.escape(bufname, ' '))
              vim.cmd('filetype detect')
              vim.cmd('doautocmd BufWinEnter')
              vim.bo.buftype = 'nofile'
            end)
            return true
          end,
          previewer = term_previewer.new_termopen_previewer({
            title = 'File Preview',
            get_command = function(entry)
              local ext = vim.fn.fnamemodify(entry.path, ':e')
              local acat =
                'atool' ..
                '  --cat' ..
                '  "' .. archive .. '"' ..
                '  "' .. entry.path .. '"'
              local cmd = acat
              if ext ~= '' then
                cmd = cmd .. ' | ' ..
                  'bat' ..
                  '  -l ' .. ext ..
                  '  --style plain ' ..
                  '  --color always ' ..
                  '  --theme base16 ' ..
                  '  --pager always' ..
                  ' || ' .. cmd -- fall back to just cat if bat fails
              end
              return cmd
            end,
          }),
          sorter = conf.generic_sorter(opts),
        }):find()
      end, { nargs = 1, complete = 'file' }) -- }}}

    end
  },
}

-- vim:fdm=marker
