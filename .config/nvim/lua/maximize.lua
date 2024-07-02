local M = {}
local ignore = function(winid)
  if vim.api.nvim_win_get_config(winid).zindex ~= nil then
    return true
  end
  if vim.wo[winid].winfixheight then
    return true
  end
end

local function height(winid)
  local bufnr = vim.fn.winbufnr(winid)
  if vim.bo[bufnr].ft == 'qf' then
    vim.w[winid].height = 10
    vim.wo[winid].winfixheight = true
  elseif vim.wo[winid].previewwindow then
    vim.w[winid].height = vim.o.previewheight
  elseif vim.wo[winid].winfixheight then
    if not vim.w[winid].height then
      vim.w[winid].height = vim.fn.winheight(winid)
    end
  end
  return vim.w[winid].height
end

local function disable()
  vim.cmd('winc =')
  vim.t.maximized = nil
  for winnr = 1, vim.fn.winnr('$') do
    local winid = vim.fn.win_getid(winnr)
    if vim.wo[winid].winfixheight then
      vim.cmd(winnr .. 'resize ' .. vim.w[winid].height)
    end
  end
end

local function update()
  if vim.t.maximized then
    -- if the current window is fixed, then pick the nearest non-fixed
    -- window and maximize that.
    if ignore(vim.fn.win_getid()) then
      local curwin = vim.fn.winnr()
      for winnr = vim.fn.winnr('$'), 1, -1 do
        local winid = vim.fn.win_getid(winnr)
        if not ignore(winid) then
          vim.cmd('noautocmd ' .. winnr .. 'winc w')
          vim.cmd('winc _')
          break
        end
      end
      vim.cmd('noautocmd ' .. curwin .. 'winc w')

    -- maximize the current window
    else
      vim.cmd('winc _')
    end

    -- set all fixed height windows to their fixed height
    for winnr = 1, vim.fn.winnr('$') do
      local winid = vim.fn.win_getid(winnr)
      if vim.wo[winid].winfixheight then
        if vim.w[winid].height then
          vim.cmd(winnr .. 'resize ' .. vim.w[winid].height)
        end
      end
    end
  end
end

local function enable()
  for winnr = 1, vim.fn.winnr('$') do
    local winid = vim.fn.win_getid(winnr)
    height(winid)
  end

  vim.o.winminheight = 0
  vim.cmd('winc _')
  vim.t.maximized = true
  update()
end

M.autocmd = function()
  local augroup = vim.api.nvim_create_augroup('maximize', {})
  vim.api.nvim_create_autocmd({ 'WinEnter', 'VimResized' }, {
    group = augroup,
    callback = function(opts)
      if not vim.t.maximized then
        if opts.event == 'VimResized' then
          disable()
        end
        return
      end
      vim.schedule(update)
    end
  })

  vim.api.nvim_create_autocmd('WinNew', {
    group = augroup,
    callback = function()
      -- depending on how the window is created it may have winfixheight set
      -- immediatly or we may need to grab it after the window is fully
      -- initialized
      local winid = vim.fn.win_getid()
      if vim.wo.winfixheight then
        height(winid)
      else
        vim.schedule(function() height(winid) end)
      end
    end
  })

  -- :pclose doesn't trigger a WinEnter, so listen for the close and schedule
  -- an update accordingly.
  vim.api.nvim_create_autocmd('WinClosed', {
    group = augroup,
    callback = function(opts)
      local winid = tonumber(opts.match)
      if vim.wo[winid].previewwindow then
        vim.schedule(update)
      end
    end
  })

  -- another :pclose workaround, but this one from supertab
  local stgroup = vim.api.nvim_create_augroup('supertab_preview_closed', {})
  vim.api.nvim_create_autocmd('User', {
    group = stgroup,
    callback = function() vim.schedule(update) end
  })
end

M.toggle = function()
  if not ignore(vim.fn.win_getid()) then
    if vim.t.maximized then
      disable()
    else
      enable()
    end
  end
end

return M
