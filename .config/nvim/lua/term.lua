local M = {}
local term_state = { bufnr = -1, winnr = -1 }
local term = function(opts)
  if not vim.api.nvim_win_is_valid(term_state.winnr) then
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local col = math.floor((vim.o.columns - width) / 2)
    local row = math.floor((vim.o.lines - height) / 2)
    local bufnr = vim.api.nvim_buf_is_valid(term_state.bufnr) and
      term_state.bufnr or
      vim.api.nvim_create_buf(false, true)
    local winnr = vim.api.nvim_open_win(bufnr, true, {
      relative = 'editor',
      width = width,
      height = height,
      col = col,
      row = row,
      style = 'minimal',
      border = 'rounded',
    })
    term_state.bufnr = bufnr
    term_state.winnr = winnr
    if vim.bo[term_state.bufnr].buftype ~= 'terminal' then
      vim.cmd.terminal()
      vim.keymap.set('t', '<esc><esc>', '<c-\\><c-n>:q<cr>', { buffer = true })
    end
    vim.cmd.startinsert()
    if opts.args ~= '' then
      vim.uv.new_timer():start(200, 0, vim.schedule_wrap(function()
        local cr = vim.api.nvim_replace_termcodes('<cr>', true, false, true)
        vim.cmd.startinsert()
        vim.fn.feedkeys(opts.args .. cr, 'nt')
      end))
    end
  else
    vim.api.nvim_win_hide(term_state.winnr)
  end
end

M.init = function()
  vim.api.nvim_create_user_command('Term', term, { nargs = '?' })
  vim.keymap.set('n', '<leader>t', ':Term<cr>', { silent = true })
  vim.keymap.set('ca', 'term', function()
    local abbrev = 'term'
    local type = vim.fn.getcmdtype()
    local pos = vim.fn.getcmdpos()
    ---@diagnostic disable-next-line: redundant-parameter
    local char = vim.fn.nr2char(vim.fn.getchar(1))
    if type == ':' and pos == #abbrev + 1 and char:match('[%s]') then
      return 'Term'
    end
    return abbrev
  end, { expr = true })
end

return M
