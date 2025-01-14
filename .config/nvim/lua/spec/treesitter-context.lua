return {{
  'nvim-treesitter/nvim-treesitter-context',
  config = function()
    require('treesitter-context').setup({
      multiline_threshold = 1, -- number of lines per context
    })

    local ext_ns = vim.api.nvim_create_namespace('treesitter-context-spec-ext')
    vim.keymap.set('n', '<leader>u', function() -- {{{
      local count = vim.v.count1
      local contexts = vim.b.treesitter_contexts
      local _jump = function(index)
        -- first check visible contexts
        if index <= #contexts then
          local context = contexts[#contexts - (index - 1)]
          vim.cmd([[ normal! m' ]]) -- update jump list
          vim.api.nvim_win_set_cursor(0, { context['line'] + 1, context['col'] })

        -- fall back to non-visible contexts
        else
          require('treesitter-context').go_to_context(index - #contexts)
        end

        -- call CursorHold now to update context highlights
        vim.cmd('doautocmd CursorHold')
      end

      -- if a count already supplied then go to it
      if count ~= 1 then
        _jump(count)

      -- otherwise set some numbered extmarks and have the user choose
      else
        -- visible contexts
        for i = 1, #contexts do
          local context = contexts[#contexts + 1 - i]
          vim.api.nvim_buf_set_extmark(0, ext_ns, context['line'], 0, {
            virt_text_pos = 'overlay',
            virt_text = { { tostring(i), 'MatchParen' } }
          })
        end

        -- non-visible contexts (displayed in 1 line floating windows)
        local index = #contexts
        local contextbuf = nil
        for winnr = 1, vim.fn.winnr('$') do
          local winid = vim.fn.win_getid(winnr)
          if vim.w[winid]['treesitter_context'] then
            contextbuf = vim.fn.winbufnr(winnr)
            for lnum = vim.fn.line('$', winid), 1, -1 do
              index = index + 1
              vim.api.nvim_buf_set_extmark(contextbuf, ext_ns, lnum - 1, 0, {
                virt_text_pos = 'overlay',
                virt_text = { { tostring(index), 'TreesitterContextLineNumber' } }
              })
            end
            break
          end
        end

        -- only one place to go, so go
        if index == 0 then
          vim.api.nvim_echo({{ 'No contexts found.', 'Error' }}, false, {})
        elseif index == 1 then
          _jump(1)
        else
          vim.cmd('redraw')
          local ok, choice = pcall(
            vim.fn.input,
            'context [' .. 1 .. '-' .. index .. ']: '
          )
          if ok and choice:match('^%d+$') then
            local loc = tonumber(choice)
            if 1 <= loc and loc <= index then
              _jump(loc)
            end
          end
        end

        vim.api.nvim_buf_clear_namespace(0, ext_ns, 0, -1)
        if contextbuf then
          vim.api.nvim_buf_clear_namespace(contextbuf, ext_ns, 0, -1)
        end
      end
    end, { silent = true }) -- }}}

    vim.keymap.set('n', '<leader>y', function() -- {{{
      local bufnr = vim.api.nvim_get_current_buf()
      local winid = vim.api.nvim_get_current_win()
      local c = vim.api.nvim_win_get_cursor(winid)
      local row, col = c[1] - 1, c[2]
      local range = {row, col, row, col + 1}

      local ok_tree, root_tree = pcall(vim.treesitter.get_parser, bufnr)
      if not ok_tree or not root_tree then
        return
      end

      local tree = root_tree:tree_for_range(range, {ignore_injections = true})
      if not tree then
        return
      end

      local parts = {}
      local accept = { 'class_definition', 'function_definition' }
      local named = tree:root():named_descendant_for_range(unpack(range))
      while named do
        if vim.list_contains(accept, named:type()) then
          for child in named:iter_children() do
            if child:type() == 'identifier' then
              parts[#parts + 1] = vim.treesitter.get_node_text(child, bufnr, {})
              break
            end
          end
        end
        named = named:parent()
      end
      if #parts > 0 then
        local result = ''
        for i = #parts, 1, -1 do
          if result ~= '' then
            result = result .. '.'
          end
          result = result .. parts[i]
        end
        if string.find(vim.o.clipboard, 'plus') then
          vim.fn.setreg('+', result)
        end
        if string.find(vim.o.clipboard, 'unnamed') or
           string.find(vim.o.clipboard, 'autoselect')
        then
          vim.fn.setreg('*', result)
        end
        vim.print('copied: ' .. result)
      else
        vim.print('No relevant context info found.')
      end
    end, { silent = true }) -- }}}

    -- replace CursorMoved with CursorHold to avoid overhead of moving
    -- around a file (also add WinResized for quicker update when resizing a
    -- window)
    local tc_au_opts = {
      group = 'treesitter_context_update',
      event = 'CursorMoved',
    }
    local tc_callback = vim.api.nvim_get_autocmds(tc_au_opts)[1].callback
    vim.api.nvim_clear_autocmds(tc_au_opts)
    vim.api.nvim_create_autocmd({ 'CursorHold', 'WinResized' }, {
      group = 'treesitter_context_update',
      callback = function(...)
        -- treesitter-context already checks filetype, buftype, etc, but will
        -- fail if the file is not modifiable
        if vim.bo[vim.api.nvim_get_current_buf()].modifiable then
          tc_callback(...) ---@diagnostic disable-line: need-check-nil
        end
      end
    })

    -- add highlighting of visible parent contexts {{{
    local sign_group = 'treesitter_context_visible'
    local sign_name = 'treesitter_context_visible_line'
    ---@diagnostic disable-next-line: missing-fields
    vim.fn.sign_define(sign_name, {
      numhl = 'TreesitterContextVisibleLine',
    })

    local hl_ns = vim.api.nvim_create_namespace('treesitter-context-spec-hi')
    local function highlight_parent(bufnr, lnum, query, parent, contexts)
      for _, match in query:iter_matches(
        parent, bufnr, 0, -1, { max_start_depth = 0 }
      ) do
        --- @cast match table<integer,TSNode>
        for id, node in pairs(match) do
          local line, col = node:start()
          if line < lnum and query.captures[id] == 'context' then
            vim.fn.sign_place(
              0,
              sign_group,
              sign_name,
              bufnr,
              { lnum = line + 1 }
            )
            vim.api.nvim_buf_add_highlight(
              bufnr,
              hl_ns,
              'TreesitterContextVisible',
              line,
              0,
              -1
            )
            if #contexts == 0 or contexts[#contexts]['line'] ~= line then
              contexts[#contexts + 1] = { line = line, col = col }
            end
          end
        end
      end
    end

    vim.api.nvim_create_autocmd(
      -- NOTE: WinScrolled included so that we clear our custom highlight,
      -- preventing it from potentially bleeding into the floating window for
      -- non-visible context lines
      { 'CursorHold', 'BufWinEnter', 'WinEnter', 'WinScrolled' },
      {
        callback = function(opts)
          if opts.event ~= 'CursorHold' then
            for winnr = 1, vim.fn.winnr('$') do
              local winbufnr = vim.fn.winbufnr(winnr)
              vim.fn.sign_unplace(sign_group, { buffer = winbufnr })
              vim.api.nvim_buf_clear_namespace(winbufnr, hl_ns, 0, -1)
            end
          end

          local bufnr = vim.api.nvim_get_current_buf()
          local winid = vim.api.nvim_get_current_win()

          vim.b[bufnr].treesitter_contexts = {}
          vim.fn.sign_unplace(sign_group, { buffer = bufnr })
          vim.api.nvim_buf_clear_namespace(bufnr, hl_ns, 0, -1)

          if vim.wo[winid].previewwindow or
             vim.bo[bufnr].filetype == '' or
             vim.bo[bufnr].buftype ~= '' or
             vim.fn.getcmdtype() ~= ''
          then
            return
          end

          local lnum = vim.fn.line('.') - 1
          local c = vim.api.nvim_win_get_cursor(winid)
          local row, col = c[1] - 1, c[2]
          local range = {row, col, row, col + 1}

          local ok_tree, root_tree = pcall(vim.treesitter.get_parser, bufnr)
          if not ok_tree or not root_tree then
            return
          end

          local langtree = root_tree
          local tree = root_tree:tree_for_range(range, {ignore_injections = true})
          if not tree then
            for _, childtree in pairs(root_tree:children()) do
              if childtree:contains(range) then
                langtree = childtree
                tree = childtree:tree_for_range(range, {ignore_injections = true})
                break
              end
            end
          end

          if not tree then
            return
          end

          local named = tree:root():named_descendant_for_range(unpack(range))
          local parents = {}
          while named do
            parents[#parents + 1] = named
            named = named:parent()
          end

          local ok_query, query = pcall(
            vim.treesitter.query.get,
            langtree:lang(),
            'context'
          )
          if not ok_query or not query then
            return
          end

          -- account for possible E315 error (nvim bug?)
          local ok, top_row = pcall(vim.fn.line, 'w0', winid)
          if ok then
            top_row = top_row - 1
            local contexts = {}
            for i = #parents, 1, -1 do
              local parent = parents[i]
              local parent_start_row = parent:range()

              -- Only process the parent if it is in view.
              if parent_start_row > top_row then
                highlight_parent(bufnr, lnum, query, parent, contexts)
              end
            end
            vim.b[bufnr].treesitter_contexts = contexts
          end
        end
      }
    ) -- }}}
  end
}}

-- vim:fdm=marker
