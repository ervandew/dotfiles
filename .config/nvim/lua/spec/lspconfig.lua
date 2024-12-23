return {
  {
    'mrded/nvim-lsp-notify',
    config = function()
      require('lsp-notify').setup({
        notify = require('notify'),
      })
    end
  },
  {
    'neovim/nvim-lspconfig',

    config = function()

      -- Diagnostics {{{

      -- ability to ignore/filter diagnostics {{{
      -- note: patterns use vim's regex
      local ignore = {}
      local ignored = function(bufnr, diagnostic)
        if not ignore[diagnostic.source] then
          return false
        end
        for _, i in ipairs(ignore[diagnostic.source]) do
          if type(i) == 'function' then
            if i(bufnr, diagnostic) then
              return true
            end
          else
            local message = diagnostic.message
            if vim.fn.substitute(message, i, '', '') ~= message then
              return true
            end
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

      -- update the sign symbols
      for _, name in ipairs({'Error', 'Warn', 'Info', 'Hint'}) do
        local hl = 'DiagnosticSign' .. name
        vim.fn.sign_define(hl, { text = '>', texthl = hl, numhl = hl })
      end

      local orig_signs_handler = vim.diagnostic.handlers.signs
      ---@diagnostic disable-next-line: inject-field
      vim.diagnostic.handlers.signs = {
        show = function(ns, bufnr, diagnostics, opts)
          -- track the highest severity diagnostic
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

          -- call the default handler with our filtered results
          local filtered = vim.tbl_values(max_severity_per_line)
          orig_signs_handler.show(ns, bufnr, filtered, opts)

          -- set a bufer local variable to the highest severity diagnostic per
          -- namespace, allowing statusline or other things to access it.
          local max_diagnostics = vim.b[bufnr].max_diagnostics or {}
          local ns_name = vim.diagnostic.get_namespace(ns).name
          max_diagnostics[ns_name] = max_diagnostic
          vim.b[bufnr].max_diagnostics = max_diagnostics
          -- force statusline to re-evaluate
          vim.wo.statusline = vim.wo.statusline
        end,
        hide = function(ns, bufnr)
          orig_signs_handler.hide(ns, bufnr)
          local max_diagnostics = vim.b[bufnr].max_diagnostics or {}
          local ns_name = vim.diagnostic.get_namespace(ns).name
          max_diagnostics[ns_name] = nil
          vim.b[bufnr].max_diagnostics = max_diagnostics
          -- force statusline to re-evaluate
          vim.wo.statusline = vim.wo.statusline
        end,
      }

      -- }}}

      -- show diagnostics (linter results) in the location list -- {{{
      local errlist_type_map = {
        [vim.diagnostic.severity.ERROR] = 'E',
        [vim.diagnostic.severity.WARN] = 'W',
        [vim.diagnostic.severity.INFO] = 'I',
        [vim.diagnostic.severity.HINT] = 'N',
      }
      vim.api.nvim_create_autocmd('DiagnosticChanged', {
        callback = function(args)
          -- all diagnostics in the current buffer
          local diagnostics = vim.diagnostic.get(args.buf)
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

          local winnr = vim.fn.bufwinnr(args.buf)
          if winnr ~= -1 then
            -- prevent error message if this is firing after the buffer was
            -- deleted
            local ok, _ = pcall(vim.fn.setloclist, winnr, filtered, 'r')
            if not ok then
              return
            end
            ok, _ = pcall(
              vim.fn.setloclist, winnr, {}, 'r', { title = 'Diagnostics' }
            )
            if not ok then
              return
            end
            -- fire autocmd to display diagnostic on the current line
            vim.cmd('doautocmd CursorHold')
          end
        end,
      }) -- }}}

      --  autocmd to echo qf/loc list entry info for current line {{{
      vim.api.nvim_create_autocmd('CursorHold', {
        pattern = '*',
        callback = function()
          if vim.fn.mode() ~= 'n' or vim.fn.expand('%') == '' then
            return
          end

          local winid = vim.fn.win_getid()
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
              if loc.user_data and type(loc.user_data) == 'string' then
                message = loc.user_data .. ': ' .. message
              else
                message = ' ' .. message
              end
              message = name .. ' - (' .. locnum .. ' of ' .. #locs .. '):' .. message
              break
            end
          end
          if #message > vim.v.echospace then
            message = string.sub(message, 1, vim.v.echospace - 3) .. '...'
          end

          if message ~= '' or (
            vim.g.lsp_diagnostic_echo and (
              vim.g.lsp_diagnostic_echo.winid ~= winid or
              vim.g.lsp_diagnostic_echo.line ~= line or
              vim.g.lsp_diagnostic_echo.col ~= col
            )
          ) then
            vim.api.nvim_echo({{ message }}, false, {})
          end

          if message ~= '' then
            -- track the position when we last echoed a message so we don't clear
            -- any current echo unless there is a chance it came from here
            -- FIXME: any way to get the current text visible in the cmdline?
            vim.g.lsp_diagnostic_echo = { winid = winid, line = line, col = col }
          else
            vim.g.lsp_diagnostic_echo = nil
          end
        end
      }) -- }}}

      vim.diagnostic.config({
        signs = true,
        underline = true, -- using italic instead in colorscheme
        virtual_text = false,
        update_in_insert = true,
      }) -- }}}

      -- Mappings {{{

      local on_list = function(options)
        local item
        if #options.items == 1 then
          item = options.items[1]
        elseif #options.items > 1 then
          -- check if all items are on the same line, and if so just
          -- use the first
          local prev_line
          local single_line = true
          for _, i in ipairs(options.items) do
            if prev_line and i.lnum ~= prev_line then
              single_line = false
              break
            end
            prev_line = i.lnum
          end
          if single_line then
            item = options.items[1]
          end
        end

        if item then
          local filename = item.filename
          local winnr = vim.fn.bufwinnr(vim.fn.bufnr('^' .. filename .. '$'))
          if winnr ~= -1 then
            vim.cmd(winnr .. 'winc w')
            vim.cmd([[ normal! m' ]]) -- update jump list
          else
            local cmd = 'split'
            if vim.fn.expand('%') == '' and
               not vim.o.modified and
               vim.fn.line('$') == 1 and
               vim.fn.getline(1) == ''
            then
              cmd = 'edit'
            end
            vim.cmd(cmd .. filename)
          end
          vim.fn.cursor(item.lnum, item.col)
        elseif #options.items > 1 then
          vim.fn.setqflist({}, ' ', options)
          vim.cmd.copen()
        end
      end

      vim.api.nvim_create_autocmd('LspAttach', {
        pattern = '*',
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.server_capabilities.definitionProvider then
            vim.keymap.set('n', '<cr>', function()
              -- for lua files, try looking up docs first
              if vim.bo.filetype == 'lua' then
                if vim.fn['lookup#Lookup']('', '') then
                  return
                end
              end

              -- for python files, see if the reference under the cursor is to an
              -- html file
              if vim.bo.filetype == 'python' then
                local line = vim.fn.getline('.')
                local possible_path = vim.fn.substitute(line,
                  "\\(.*[[:space:]\"',(\\[{><]\\|^\\)\\(.*\\%" ..
                  vim.fn.col('.') .. "c.\\{-}\\)\\([[:space:]\"',)\\]}<>].*\\|$\\)",
                  '\\2',
                  ''
                )
                local index = string.find(possible_path, '.html', 1, true)
                if index == #possible_path - 4 then
                  vim.cmd('Grep! --files')
                  return
                end
              end

              -- now we can run lsp definition lookup
              vim.lsp.buf.definition({on_list = on_list})
            end, { buffer = bufnr, silent = true })
          end
        end
      })

      -- }}}

      -- Servers {{{

      local lspconfig = require('lspconfig')

      -- pyright {{{
      lspconfig.pyright.setup({
        settings = {
          python = {
            -- alternate way to set a global python path
            -- pythonPath = '/usr/bin/python',
            -- NOTE: to avoid a bunch of pyright type errors w/ django
            -- $ pip install django-stubs
          },
        },
        on_attach = function(client)
          if client.root_dir then
            lspconfig.pyright.commands.PyrightSetPythonPath[1](
              client.root_dir .. '/.virtualenv/bin/python'
            )
          end

          ignore['Pyright'] = {
            '"\\(__\\|args\\|kwargs\\|self\\)" is not accessed',
            -- 'No overloads',
            -- 'not supported for "None"',
            -- 'Object of type "None"',
            (function(bufnr, d)
              if d.code == 'reportWildcardImportFromLibrary' and
                 string.find(vim.fn.bufname(bufnr), '__init__.py') then
                return true
              end
              -- ignore 'not accessed' hints for parameters
              if d._tags and d._tags.unnecessary then
                local ok, node = pcall(vim.treesitter.get_node, {
                  bufnr = bufnr,
                  pos = { d.lnum, d.col },
                })
                if ok then
                  local parent = node ~= nil and node:parent() or nil
                  if parent ~= nil and string.find(parent:type(), 'splat_pattern') then
                    parent = parent:parent()
                  end
                  local parent_type = parent ~= nil and parent:type() or ''
                  if parent_type == 'parameters' or
                     parent_type == 'default_parameter' or
                     parent_type == 'lambda_parameters' then
                    return true
                  end
                end
              end
              return false
            end),
          }

        end,
      }) -- }}}

      -- ruff {{{
      lspconfig.ruff.setup({})
      -- }}}

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

      -- }}}

    end,
  }
}

-- vim:fdm=marker
