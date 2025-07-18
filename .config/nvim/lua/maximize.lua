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
  if bufnr ~= -1 then
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
    local curwinid = vim.fn.win_getid()

    -- if the current window is floating don't do anything
    if vim.api.nvim_win_get_config(curwinid).zindex ~= nil then
      return
    end

    -- if the current window is fixed, then pick the nearest non-fixed window
    -- and maximize that.
    if ignore(curwinid) then
      local curwin = vim.fn.winnr()
      for winnr = vim.fn.winnr('$'), 1, -1 do
        if winnr < curwin then
          local winid = vim.fn.win_getid(winnr)
          if not ignore(winid) then
            vim.cmd('noautocmd ' .. winnr .. 'winc w')
            vim.cmd('winc _')
            break
          end
        end
      end
      vim.schedule(function()
        vim.cmd('noautocmd ' .. vim.fn.win_id2win(curwinid) .. 'winc w')
      end)

    -- maximize the current window
    else
      vim.cmd('winc _')
    end

    -- set all fixed height windows to their fixed height
    for winnr = 1, vim.fn.winnr('$') do
      local winid = vim.fn.win_getid(winnr)
      if vim.wo[winid].winfixheight then
        -- for loclist windows, only resize the one associated with the current
        -- window
        if vim.fn.getwininfo(winid)[1].loclist == 1 then
          local pwinid = vim.fn.getloclist(winid, { filewinid = 0 }).filewinid
          if winid == curwinid or pwinid == curwinid then
            vim.cmd(winnr .. 'resize ' .. vim.w[winid].height)
          end
        elseif vim.w[winid].height then
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

M.toggle = function()
  if not ignore(vim.fn.win_getid()) then
    if vim.t.maximized then
      disable()
    else
      enable()
    end
  end
end

M.init = function()
  vim.keymap.set('n', '<space><space>', M.toggle)

  local augroup = vim.api.nvim_create_augroup('maximize', {})
  vim.api.nvim_create_autocmd({ 'WinEnter', 'VimResized' }, {
    group = augroup,
    callback = function(opts)
      if opts.event == 'WinEnter' then
        -- check if we are entering the last and only non-floating window, and
        -- if it's a fixed height window, we'll open a new empty window to take
        -- its place.
        vim.schedule(function()
          local winid = vim.fn.win_getid()
          if vim.wo[winid].winfixheight then
            local count = 0
            for winnr = 1, vim.fn.winnr('$') do
              if not vim.api.nvim_win_get_config(vim.fn.win_getid(winnr)).zindex then
                count = count + 1
              end
            end
            if count == 1 then
              vim.cmd('above new')
              vim.cmd.winc('w')
              vim.cmd.resize(vim.w.height or 10)
              vim.cmd.winc('w')
            end
          end
        end)
      end

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
end

return M
