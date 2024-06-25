-- local plugins
return {
  {
    dir = vim.fn.stdpath('config') .. '/vimscript',
    config = function()
      -- diff
      vim.keymap.set('ca', 'dn', 'DiffNextChange')
      vim.keymap.set('ca', 'dp', 'DiffPrevChange')

      -- indentdetect
      vim.api.nvim_create_autocmd('FileType', {
        pattern = '*',
        callback = function()
          if vim.fn.exists(':IndentDetect') == 2 then
            vim.cmd.IndentDetect()
          end
        end
      })

      -- ranger
      vim.keymap.set('n', '<leader>/', ':Ranger<cr>', { silent = true })
    end
  },
  {
    dir = '~/.vim/bundle/eclim',
    init = function()
      -- lspconfig spec handles this
      vim.g.EclimShowCurrentError = 0
      -- mimic some lsp behavior
      vim.api.nvim_create_autocmd('BufWritePost', {
        pattern = '*.py',
        callback = function()
          vim.schedule(function()
            local diagnostic = nil
            local max_severity = nil
            if vim.fn['eclim#project#problems#IsProblemsList']() then
              local severities = {
                e = vim.diagnostic.severity.ERROR,
                w = vim.diagnostic.severity.WARN,
              }
              for _, problem in ipairs(vim.fn.getloclist(0)) do
                local severity = severities[problem['type']]
                if severity and (not max_severity or severity < max_severity) then
                  max_severity = severity
                  diagnostic = problem
                end
              end
            end
            if diagnostic ~= nil then
              diagnostic.severity = max_severity
            end
            vim.b.diagnostic = diagnostic
            vim.o.statusline=vim.o.statusline
          end)
        end
      })
    end,
  },
}
