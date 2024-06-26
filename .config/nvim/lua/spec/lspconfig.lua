return {{
  'neovim/nvim-lspconfig',

  config = function()
    -- update the sign symbol
    for _, name in ipairs({'Error', 'Warn', 'Info', 'Hint'}) do
      local hl = 'DiagnosticSign' .. name
      vim.fn.sign_define(hl, { text = '>', texthl = hl, numhl = hl })
    end

    -- ability to ignore/filter diagnostics {{{
    local ignore = {
      -- FIXME: move to pyright setup (insert into 'ignore' table
      Pyright = { -- {{{
        '"__" is not accessed',
        'No overloads',
        'not supported for "None"',
        'Object of type "None"',
        (function(bufnr, d)
          if d.code == 'reportWildcardImportFromLibrary' and
             string.find(vim.fn.bufname(bufnr), '__init__.py') then
            return true
          end
          -- ignore 'not accessed' hints for parameters
          if d._tags and d._tags.unnecessary then
            local node = vim.treesitter.get_node({
              bufnr = bufnr,
              pos = { d.lnum, d.col },
            })
            local parent = node ~= nil and node:parent() or nil
            if parent ~= nil and string.find(parent:type(), 'splat_pattern') then
              parent = parent:parent()
            end
            local parent_type = parent ~= nil and parent:type() or ''
            if parent_type == 'parameters' or
               parent_type == 'default_parameter' then
              return true
            end
          end
          return false
        end),
      }, -- }}}
    }
    local ignored = function(bufnr, diagnostic)
      if not ignore[diagnostic.source] then
        return false
      end
      for _, i in ipairs(ignore[diagnostic.source]) do
        if type(i) == 'function' then
          if i(bufnr, diagnostic) then
            return true
          end
        elseif string.find(diagnostic.message, i) then
          return true
        end
      end
      return false
    end

    local orig_set = vim.diagnostic.set
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.diagnostic.set = function(namespace, bufnr, diagnostics, opts)
      local filtered = {}
      for _, diagnostic in pairs(diagnostics) do
        if not ignored(bufnr, diagnostic) then
          table.insert(filtered, diagnostic)
        end
      end
      orig_set(namespace, bufnr, filtered, opts)
    end

    local ns = vim.api.nvim_create_namespace('filtered')
    local orig_signs_handler = vim.diagnostic.handlers.signs
    vim.diagnostic.handlers.signs = {
      show = function(_, bufnr, _, opts)
        -- all diagnostics in the current buffer
        local diagnostics = vim.diagnostic.get(bufnr)

        -- track the highest severity for the whole buffer
        local max_diagnostic = nil
        -- only show sign for the highest severity
        local max_severity_per_line = {}
        for _, diagnostic in pairs(diagnostics) do
          local m = max_severity_per_line[diagnostic.lnum]
          if not m or diagnostic.severity < m.severity then
            max_severity_per_line[diagnostic.lnum] = diagnostic
          end

          if max_diagnostic == nil or
             diagnostic.severity < max_diagnostic.severity
          then
            max_diagnostic = diagnostic
          end
        end

        -- set a bufer local variable to the highest severity, allowing
        -- statusline or other things to access it.
        vim.api.nvim_buf_set_var(bufnr, 'diagnostic', max_diagnostic)
        -- force statusline to re-evaluate
        vim.o.statusline = vim.o.statusline

        -- call the default handler with our filtered results
        local filtered = vim.tbl_values(max_severity_per_line)
        orig_signs_handler.show(ns, bufnr, filtered, opts)
      end,
      hide = function(_, bufnr)
        pcall(function() vim.api.nvim_buf_del_var(bufnr, 'diagnostic') end)
        -- force statusline to re-evaluate
        vim.o.statusline = vim.o.statusline

        orig_signs_handler.hide(ns, bufnr)
      end,
    } -- }}}

    -- show diagnostics (linter results) in the location list -- {{{
    local errlist_type_map = {
      [vim.diagnostic.severity.ERROR] = 'E',
      [vim.diagnostic.severity.WARN] = 'W',
      [vim.diagnostic.severity.INFO] = 'I',
      [vim.diagnostic.severity.HINT] = 'N',
    }
    vim.api.nvim_create_autocmd('DiagnosticChanged', {
      callback = function(args)
        local diagnostics = args.data.diagnostics
        local filtered = {}
        for _, d in ipairs(diagnostics) do
          table.insert(filtered, {
            bufnr = d.bufnr,
            lnum = d.lnum + 1,
            col = d.col and (d.col + 1) or nil,
            end_lnum = d.end_lnum and (d.end_lnum + 1) or nil,
            end_col = d.end_col and (d.end_col + 1) or nil,
            text = d.message,
            type = errlist_type_map[d.severity] or 'E',
            user_data = d.code,
          })
        end
        table.sort(filtered, function(a, b)
          if a.bufnr == b.bufnr then
            if a.lnum == b.lnum then
              return a.col < b.col
            else
              return a.lnum < b.lnum
            end
          else
            return a.bufnr < b.bufnr
          end
        end)

        local winnr = vim.fn.bufwinnr(args.file)
        vim.fn.setloclist(winnr, filtered, 'r')
        vim.fn.setloclist(winnr, {}, 'r', { title = 'Diagnostics' })
        -- fire autocmd to display diagnostic on the current line
        vim.cmd('doautocmd CursorMoved')
      end,
    }) -- }}}

    --  autocmd to echo qf/loc list entry info for current line {{{
    vim.api.nvim_create_autocmd('CursorMoved', {
      pattern = '*',
      callback = function()
        if vim.fn.mode() ~= 'n' or vim.fn.expand('%') == '' then
          return
        end

        local line = vim.fn.line('.')
        local col = vim.fn.col('.')
        local locnum = 0
        local loccol = 0
        local llocs = vim.fn.getloclist(0)
        local qlocs = vim.fn.getqflist()
        local bufname = vim.fn.expand('%')
        local lastline = vim.fn.line('$')
        local message = ''
        for name, locs in pairs({ qf = qlocs, loc = llocs }) do
          for index, loc in ipairs(locs) do
            if vim.fn.bufname(loc.bufnr) == bufname and
               (loc.lnum == line or (loc.lnum > lastline and line == lastline))
            then
              if locnum == 0 or (col >= loc.col and loc.col ~= loccol) then
                locnum = index
                loccol = loc.col
              end
            end
          end
          if locnum > 0 then
            local loc = locs[locnum]
            message = vim.fn.substitute(loc.text, '^\\s\\+', '', '')
            message = vim.fn.substitute(message, '\n', ' ', 'g')
            message = vim.fn.substitute(message, '\t', '  ', 'g')
            message = (loc.user_data and (loc.user_data .. ': ') or ' ') .. message
            message = name .. ' - (' .. locnum .. ' of ' .. #locs .. '):' .. message
            break
          end
        end
        if #message > vim.v.echospace then
          message = string.sub(message, 1, vim.v.echospace - 3) .. '...'
        end
        vim.api.nvim_echo({{ message }}, false, {})
      end
    }) -- }}}

    vim.diagnostic.config({
      signs = true,
      underline = true, -- using italic  instead in colorscheme
      virtual_text = false,
      update_in_insert = false,
    })

    local lspconfig = require('lspconfig')

    -- pyright -- {{{
    -- lspconfig.pyright.setup({
    --   settings = {
    --     python = {
    --       -- alternate way to set a global python path
    --       -- pythonPath = '/usr/bin/python',
    --       -- NOTE: to avoid a bunch of pyright type errors w/ django
    --       -- $ pip install django-stubs 
    --     },
    --   },
    --   on_attach = function(client, bufnr)
    --     lspconfig.pyright.commands.PyrightSetPythonPath[1](
    --       client.root_dir .. '/.virtualenv/bin/python'
    --     )
    --   end,
    -- }) -- }}}

    -- lua-language-server (lua_ls) {{{
    local library = {
      vim.env.VIMRUNTIME,
      '${3rd}/luv/library',
    }
    local lazy = vim.fn.stdpath('data') .. '/lazy/'
    for _, dir in ipairs(vim.fn.readdir(lazy)) do
      library[#library + 1] = lazy .. dir
    end

    lspconfig.lua_ls.setup({
      settings = {
        Lua = {
          runtime = { version = 'LuaJIT' },
          workspace = {
            checkThirdParty = false,
            library = library,
          }
        }
      },
    }) -- }}}
  end,
}}

-- vim:fdm=marker
