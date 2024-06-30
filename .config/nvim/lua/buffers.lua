local M = {}
local buffers_tab_id_gen = 0
local tab_prev = nil
local tab_count = nil

local content

local function get_buffers()
  local result = {}
  local buffer_ids = vim.api.nvim_list_bufs()
  local cwd = vim.fn.getcwd()
  for _, buffer_id in ipairs(buffer_ids) do
    local name = vim.fn.bufname(buffer_id)
    if name == '' then
      name = '[No Name]'
    end
    if name ~= '[buffers]' then
      local dir = vim.fn.fnamemodify(name, ':p:h')
      if string.find(dir, cwd, 1, true) == 1 then
        dir = string.sub(dir, #cwd + 2)
      end
      result[#result + 1] = {
        bufnr = buffer_id,
        hidden = vim.fn.bufwinid(buffer_id) == -1,
        dir = dir,
        file = vim.fn.fnamemodify(name, ':p:t'),
      }
    end
  end
  return result
end

local function open_next_hidden_tab_buffer(current)
  local allbuffers = get_buffers()

  -- build list of buffers open in other tabs to exclude
  local tabbuffers = {}
  for tabnr = 1, vim.fn.tabpagenr('$') do
    if tabnr ~= vim.fn.tabpagenr() then
      for _, bnum in ipairs(vim.fn.tabpagebuflist(tabnr)) do
        tabbuffers[#tabbuffers + 1] = bnum
      end
    end
  end

  -- build list of buffers not open in any window, and last seen on the
  -- current tab.
  local hiddenbuffers = {}
  for _, buffer in ipairs(allbuffers) do
    local bufnr = buffer.bufnr
    if bufnr ~= current and
       not vim.list_contains(tabbuffers, bufnr) and
       vim.fn.bufwinnr(bufnr) == -1
    then
      local buffers_tab_id = vim.b[bufnr].buffers_tab_id
      if buffers_tab_id == vim.t.buffers_tab_id then
        if bufnr < current then
          local updated = { bufnr }
          vim.list_extend(updated, hiddenbuffers)
          hiddenbuffers = updated
        else
          hiddenbuffers[#hiddenbuffers] = bufnr
        end
      end
    end
  end

  -- we found a hidden buffer, so open it
  if #hiddenbuffers > 0 then
    vim.cmd('buffer ' .. hiddenbuffers[1])
    vim.cmd('doautocmd BufEnter')
    vim.cmd('doautocmd BufWinEnter')
    vim.cmd('doautocmd BufReadPost')

    return hiddenbuffers[1]
  end
  return 0
end

local function open_file(cmd)
  local line = vim.fn.line('.')
  if line > #vim.b.buffers then
    return
  end

  local file = vim.fn.bufname(vim.b.buffers[line].bufnr)

  -- First check if the file is already open, and if so just go to it
  local winnr = vim.fn.bufwinnr(vim.fn.bufnr('^' .. file .. '$'))
  if winnr ~= -1 then
    vim.cmd('close')
    vim.cmd(winnr .. 'winc w')
    return
  end

  -- prevent opening the buffer in a split of temp tool window, or attempting
  -- to switch to a windown that no longer exists
  winnr = vim.b.winnr
  local winid = vim.fn.win_getid(winnr)
  if vim.wo[winid].winfixheight or
     vim.wo[winid].winfixwidth or
     winnr > vim.fn.winnr('$')
  then
    winnr = 1
    winid = vim.fn.win_getid(winnr)
    while vim.wo[winid].winfixheight or vim.wo[winid].winfixwidth do
      winnr = winnr + 1
      winid = vim.fn.win_getid(winnr)
      if winnr > vim.fn.winnr('$') then
        winnr = winnr - 1
        break
      end
    end
  end

  -- if the window buffer is a no name and action is split, use edit instead.
  if cmd == 'split' and
     vim.fn.expand('%') == '' and
     not vim.o.modified and
     line('$') == 1 and
     vim.fn.getline(1) == ''
  then
    cmd = 'edit'
  end

  vim.cmd('close')
  vim.cmd(winnr .. 'winc w')
  vim.cmd(cmd .. ' ' .. file)
end

local function delete_file()
  local line = vim.fn.line('.')
  if line > #vim.b.buffers then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local buffer = vim.b.buffers[line]
  local winnr = vim.fn.winnr()

  -- if the buffer is currently open in a window, check if it's the last
  -- content window or not, so we can handle it accordingly
  local bufwin = vim.fn.bufwinnr(buffer.bufnr)
  local loadnext = false
  if bufwin ~= -1 then
    vim.cmd(bufwin .. 'winc w')
    -- check if there is a window above
    vim.cmd('winc k')
    -- check if there is a window below
    if vim.fn.winnr() == bufwin then
      vim.cmd('winc j')
    end
    if vim.fn.winnr() == bufwin or vim.fn.winnr() == winnr then
      vim.cmd('above new')
      loadnext = true
    end
  end

  vim.api.nvim_buf_delete(buffer.bufnr, {})

  if loadnext then
    local delete_bufnr = vim.fn.bufnr()
    open_next_hidden_tab_buffer(buffer.bufnr)
    -- delete the old no name buffer
    vim.api.nvim_buf_delete(delete_bufnr, {})
  end

  winnr = vim.fn.bufwinnr(bufnr)
  vim.cmd(winnr .. 'winc w')
  content()
end

local function only()
  for _, buffer in ipairs(vim.b.buffers) do
    if buffer.hidden then
      vim.api.nvim_buf_delete(buffer.bufnr, {})
    end
  end
  content()
end

function content()
  local buffers = get_buffers()
  local maxfilelength = 0
  for _, buffer in ipairs(buffers) do
    local file = buffer.file
    if #file > maxfilelength then
      maxfilelength = #buffer.file
    end
  end

  table.sort(buffers, function(a, b)
    return a.file < b.file
  end)

  local lines = {}
  local buflist = {}
  local tabid = vim.t.buffers_tab_id
  for _, buffer in ipairs(buffers) do
    if vim.b[buffer.bufnr].buffers_tab_id == tabid then
      local pad = maxfilelength - #buffer.file + 2
      local line = buffer.hidden and 'hidden' or 'active'
      line = line .. '  ' .. buffer.file
      if buffer.dir ~= '' then
        while pad > 0 do
          line = line .. ' '
          pad = pad - 1
        end
        line = line .. buffer.dir
      end
      lines[#lines + 1] = line
      buflist[#buflist + 1] = buffer
    end
  end

  lines[#lines + 1] = ''
  lines[#lines + 1] = '" use ? to view help'

  -- keep a reference to the window buffers was invoked from
  local winnr = vim.fn.winnr()

  vim.bo.modifiable = true
  vim.bo.readonly = false
  vim.api.nvim_buf_set_lines(0, 0, vim.fn.line('$') + 1, false, lines)
  vim.bo.modified = false
  vim.bo.modifiable = false
  vim.bo.readonly = true

  if vim.fn.line('.') >= vim.fn.line('$') - 2 then
    vim.fn.cursor(vim.fn.line('$') - 2, 0)
  end

  vim.b.buffers = buflist
  -- store the previous window as a buffer variable, so we can open files
  -- relative to that.
  if winnr ~= vim.fn.winnr() then
    vim.b.winnr = winnr
  end

  vim.bo.ft = 'buffers'
  vim.cmd('hi link BufferActive Special')
  vim.cmd('hi link BufferHidden Comment')
  vim.cmd('syntax match BufferActive /^active\\s/')
  vim.cmd('syntax match BufferHidden /^hidden\\s/')
  vim.cmd('syntax match Comment /^".*/')

  local opts = { buffer = true, silent = true }
  vim.keymap.set('n', '<cr>', function() open_file('edit') end, opts)
  vim.keymap.set('n', 'E',    function() open_file('edit') end, opts)
  vim.keymap.set('n', 'S',    function() open_file('split') end, opts)
  vim.keymap.set('n', 'D',    delete_file, opts)
  vim.keymap.set('n', 'O',    only, opts)
  vim.keymap.set('n', 'R',    content, opts)
  vim.keymap.set('n', 'q',    ':q<cr>', opts)
end

M.tab_tracking = function()
  for tabnr = 1, vim.fn.tabpagenr('$') do
    local tab_id = vim.t[tabnr].buffers_tab_id
    if not tab_id then
      buffers_tab_id_gen = buffers_tab_id_gen + 1
      local buffers_tab_id = buffers_tab_id_gen
      vim.t[tabnr].buffers_tab_id = buffers_tab_id
      for _, bufnr in ipairs(vim.fn.tabpagebuflist(tabnr)) do
        local btab_id = vim.b[bufnr].buffers_tab_id
        if not btab_id then
          vim.b[bufnr].buffers_tab_id = buffers_tab_id
        end
      end
    end
  end

  local augroup vim.api.nvim_create_augroup('buffers_tab_tracking', {})
  vim.api.nvim_create_autocmd({ 'BufWinEnter', 'BufWinLeave' }, {
    group = augroup,
    pattern = '*',
    callback = function()
      -- track the last tab a buffer was loaded in
      local bufnr = vim.fn.bufnr('%')

      if not vim.api.nvim_buf_is_loaded(bufnr) and vim.b.buffers_tab_id then
        vim.b.buffers_tab_id = nil
      end

      -- check if the buffer is loaded in another tab
      local other_tab = nil
      for tabnr = 1, vim.fn.tabpagenr('$') do
        if tabnr ~= vim.fn.tabpagenr() then
          local buflist = vim.fn.tabpagebuflist(tabnr)
          if vim.list_contains(buflist, bufnr) then
            other_tab = tabnr
            break
          end
        end
      end

      if not vim.b.buffers_tab_id and not other_tab then
        vim.b.buffers_tab_id = vim.t.buffers_tab_id
      end
    end
  })
  vim.api.nvim_create_autocmd('TabEnter', {
    group = augroup,
    pattern = '*',
    callback = function()
      if tab_count and tab_count > vim.fn.tabpagenr('$') then
        -- delete any buffers associated with the closed tab
        for _, buffer in ipairs(get_buffers()) do
          local buffers_tab_id = vim.b[buffer.bufnr].buffers_tab_id
          if buffers_tab_id == tab_prev and buffer.hidden then
            vim.api.nvim_buf_delete(buffer.bufnr, {})
          end
        end
      end
    end
  })
  vim.api.nvim_create_autocmd('TabLeave', {
    group = augroup,
    pattern = '*',
    callback = function()
      tab_prev = vim.t.buffers_tab_id
      tab_count = vim.fn.tabpagenr('$')
    end
  })
end

M.delete = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local windows = 0
  for winnr = 1, vim.fn.winnr('$') do
    local winid = vim.fn.win_getid(winnr)
    -- exclude any windows with a fixed height or width, as these are most
    -- likely some sort of tool window (tag list, etc)
    if not (vim.w[winid].winfixheight or vim.w[winid].winfixwidth) then
      windows = windows + 1
    end
  end

  if windows == 1 then
    vim.cmd('new')
    -- try loading a hidden buffer from the current tab
    open_next_hidden_tab_buffer(bufnr)
  end

  vim.api.nvim_buf_delete(bufnr, {})
  vim.cmd('redraw') -- force tabline to update
end

M.toggle = function()
  local buffers_bufnr = nil
  for _, bufnr in ipairs(vim.fn.tabpagebuflist()) do
    if vim.fn.bufname(bufnr) == '[buffers]' then
      buffers_bufnr = bufnr
      break
    end
  end

  if buffers_bufnr then
    vim.api.nvim_buf_delete(buffers_bufnr, {})
    return
  end

  vim.cmd('noautocmd botright 10sview [buffers]')
  vim.wo.wrap = false
  vim.wo.winfixheight = true
  vim.bo.swapfile = false
  vim.bo.buflisted = false
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.cmd('doautocmd WinNew')
  vim.cmd('doautocmd WinEnter')

  content()
end

return M
