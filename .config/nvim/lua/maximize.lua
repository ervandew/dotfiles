local M = {}
local ignore = function()
  if vim.api.nvim_win_get_config(0).zindex ~= nil then
    return true
  end
  if vim.o.winfixheight then
    return true
  end
end

local augroup = vim.api.nvim_create_augroup('maximize', {})
vim.api.nvim_create_autocmd({ 'WinEnter', 'VimResized' }, {
  group = augroup,
  callback = function()
    if not vim.t.maximized then
      return
    end
    if not ignore() then
      vim.cmd('winc _')
    elseif vim.o.winfixheight and vim.w.height then
      vim.cmd('resize ' .. vim.w.height)
    end
  end
})
vim.api.nvim_create_autocmd('WinNew', {
  group = augroup,
  callback = function()
    if not vim.t.maximized then
      return
    end
    vim.schedule(function()
      if vim.o.winfixheight then
        vim.w.height = vim.fn.winheight(0)
      end
    end)
  end
})
vim.o.winminheight = 0

M.toggle = function()
  if not ignore() then
    if vim.t.maximized then
      vim.cmd('winc =')
      vim.t.maximized = nil
      local winnr = 1
      while winnr <= vim.fn.winnr('$') do
        local winid = vim.fn.win_getid(winnr)
        if vim.wo[winid].winfixheight then
          vim.cmd(winnr .. 'resize ' .. vim.w[winid].height)
          vim.api.nvim_win_del_var(winid, 'height')
        end
        winnr = winnr + 1
      end
    else
      local winnr = 1
      while winnr <= vim.fn.winnr('$') do
        local winid = vim.fn.win_getid(winnr)
        if vim.wo[winid].winfixheight then
          vim.w[winid].height = vim.fn.winheight(winnr)
        end
        winnr = winnr + 1
      end

      vim.cmd('winc _')
      vim.t.maximized = true
    end
  end
end

return M
