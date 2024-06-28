return {
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
            local bufnr = vim.api.nvim_get_current_buf()
            local winid = vim.api.nvim_get_current_win()
            local diagnostic = nil
            local max_severity = nil
            if vim.fn['eclim#project#problems#IsProblemsList']() then
              local severities = {
                e = vim.diagnostic.severity.ERROR,
                w = vim.diagnostic.severity.WARN,
              }
              for _, problem in ipairs(vim.fn.getloclist(winid)) do
                if problem['bufnr'] == bufnr then
                  local severity = severities[problem['type']]
                  if severity and (not max_severity or severity < max_severity) then
                    max_severity = severity
                    diagnostic = problem
                  end
                end
              end
            end
            if diagnostic ~= nil then
              diagnostic.severity = max_severity
            end
            vim.b[bufnr].diagnostic = diagnostic
            vim.o.statusline=vim.o.statusline
          end)
        end
      })
    end,
  },
}
