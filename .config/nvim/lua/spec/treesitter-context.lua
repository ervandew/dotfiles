return {{
  'nvim-treesitter/nvim-treesitter-context',
  config = function()
    require('treesitter-context').setup({
      multiline_threshold = 1, -- number of lines per context
    })

    -- replace CursorMoved with CursorHold to avoid overhead of moving
    -- around a file
    local tc_au_opts = {
      group = 'treesitter_context_update',
      event = 'CursorMoved',
    }
    local tc_callback = vim.api.nvim_get_autocmds(tc_au_opts)[1].callback
    vim.api.nvim_clear_autocmds(tc_au_opts)
    vim.api.nvim_create_autocmd('CursorHold', {
      group = 'treesitter_context_update',
      callback = tc_callback,
    })

    local sign_group = 'treesitter_context_visible'
    local sign_name = 'treesitter_context_visible_line'
    ---@diagnostic disable-next-line: missing-fields
    vim.fn.sign_define(sign_name, {
      numhl = 'TreesitterContextVisibleLine',
    })

    local ns = vim.api.nvim_create_namespace('treesitter-context-spec')
    local function highlight_parent(bufnr, lnum, query, parent)
      for _, match in query:iter_matches(
        parent, bufnr, 0, -1, { max_start_depth = 0 }
      ) do
        --- @cast match table<integer,TSNode>
        for id, node in pairs(match) do
          local line = node:start()
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
              ns,
              'TreesitterContextVisible',
              line,
              0,
              -1
            )
          end
        end
      end
    end

    vim.api.nvim_create_autocmd('CursorHold', {
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local winid = vim.api.nvim_get_current_win()
        vim.fn.sign_unplace(sign_group, { buffer = bufnr })
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

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

        local top_row = vim.fn.line('w0', winid) - 1
        for i = #parents, 1, -1 do
          local parent = parents[i]
          local parent_start_row = parent:range()

          -- Only process the parent if it is in view.
          if parent_start_row > top_row then
            highlight_parent(bufnr, lnum, query, parent)
          end
        end
      end
    })
  end
}}
