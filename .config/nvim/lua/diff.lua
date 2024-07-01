local M = {}

local function syntax(line, col)
  return vim.fn.synIDattr(vim.fn.diff_hlID(line, col), 'name')
end

local function next_prev_line(direction, names)
  local lnum = vim.fn.line('.')
  local line = vim.fn.getline('.')
  local index = direction == 'next' and 0 or (#line - 1)
  while (direction == 'next' and index < #line) or
        (direction == 'prev' and index >= 0)
  do
    local found = nil
    for _, name in ipairs(names) do
      if syntax(lnum, index + 1) == name then
        vim.fn.cursor(0, index + 1)
        -- edge case where prev command needs to move the cursor to the front of
        -- the change.
        if direction == 'prev' then
          while index >= 0 and syntax(lnum, index + 1):match(name) do
            index = index - 1
          end
          vim.fn.cursor(0, index + 2)
        end
        found = true
        break
      end
    end
    if found then
      break
    end
    index = index + (direction == 'next' and 1 or -1)
  end

  if vim.fn.col('.') == 1 and line[0] == ' ' then
    vim.cmd('normal! _')
  end
end

local function next_prev(direction)
  local count = vim.v.count == 0 and 1 or vim.v.count
  while count > 0 do
    local continue = false
    local line = vim.fn.line('.')
    local col = vim.fn.col('.')
    local cur = syntax(line, col)
    if cur == 'DiffChange' or cur == 'DiffText' then
      if cur == 'DiffText' then
        next_prev_line(direction, { 'DiffChange' })
      end
      next_prev_line(direction, { 'DiffText' })
      if col ~= vim.fn.col('.') then
        count = count - 1
        continue = true
      end
    end

    if not continue then
      -- handle blocks of changes which the default vim key bindings would skip.
      if cur:match('^Diff') ~= nil then
        vim.fn.cursor(vim.fn.line('.') + (direction == 'next' and 1 or -1), 1)
        -- edge case where next line is an add, so stop on it
        local next = syntax(vim.fn.line('.'), vim.fn.col('.'))
        if next == 'DiffAdd' and cur ~= 'DiffAdd' then
          if vim.fn.col('.') == 1 and
             vim.fn.getline(vim.fn.line('.'))[1] == ' '
          then
            vim.cmd('normal! _')
          end
          count = count - 1
          continue = true
        end

        -- re-execute the DiffChange/DiffText block above on the new line
        continue = true
      end
    end
    if not continue then
      -- FIXME: prev doesn't work as well since [c jumps to the start of a change
      -- block, skipping other changes in the block that our command should
      -- visit.  May need to abandon use of the vim bindings.
      vim.cmd('normal! ' .. (direction == 'next' and ']c' or '[c'))
      next_prev_line(direction, { 'DiffText', 'DiffAdd' })
      count = count - 1

      if count == 0 and
         cur == '' and
         not syntax(vim.fn.line('.'), vim.fn.col('.')):match('^Diff')
      then
        vim.fn.cursor(vim.fn.line('.') + (direction == 'next' and -1 or 1), 1)
      end
    end
  end
end

local function commands_toggle(bufnr, on)
  if on then
    vim.keymap.set('n', '<leader>dn', function()
      next_prev('next')
    end, { buffer = bufnr })
    vim.keymap.set('n', '<leader>dp', function()
      next_prev('prev')
    end, { buffer = bufnr })
  else
    pcall(function() vim.keymap.del('n', '<leader>dn', { buffer = bufnr }) end)
    pcall(function() vim.keymap.del('n', '<leader>dp', { buffer = bufnr }) end)
  end
end

local function commands()
  for tabnr = 1, vim.fn.tabpagenr('$') do
    for winnr = 1, vim.fn.winnr('$') do
      local winid = vim.fn.win_getid(winnr, tabnr)
      commands_toggle(vim.fn.winbufnr(winid), vim.wo[winid].diff)
    end
  end
end

M.last_saved = function()
  -- diff a modified file with the last saved version.
  if vim.bo.modified then
    local bufnr = vim.fn.bufnr()
    local winnum = vim.fn.winnr()
    local filetype = vim.bo.ft
    vim.cmd('vertical belowright new | r #')
    vim.cmd('1,1delete _')
    vim.cmd('diffthis')
    vim.cmd('file [Last Saved]')
    vim.bo.buftype = 'nofile'
    vim.bo.bufhidden = 'wipe'
    vim.bo.buflisted = false
    vim.bo.swapfile = false
    vim.bo.readonly = true
    vim.bo.filetype = filetype

    local diff_bufnr = vim.fn.bufnr()
    vim.api.nvim_create_autocmd('BufUnload', {
      buffer = diff_bufnr,
      callback = function() vim.cmd('diffoff!') end,
      once = true,
    })
    vim.api.nvim_create_autocmd('BufUnload', {
      buffer = bufnr,
      callback = function()
        vim.schedule(function()
          local diff_winnr = vim.fn.bufwinnr(diff_bufnr)
          if diff_winnr ~= -1 then
            if vim.fn.winnr('$') == 1 then
              vim.cmd('new')
            end
            vim.cmd(diff_winnr .. 'winc w')
            vim.cmd('BufferDelete')
          end
        end)
      end,
      once = true,
    })
    vim.cmd(winnum .. 'winc w')
    vim.cmd('diffthis')
  else
    vim.api.nvim_echo({{ 'No changes', 'WarningMsg' }}, true, {})
  end
end

M.autocmd = function()
  vim.api.nvim_create_autocmd('OptionSet', {
    pattern = 'diff',
    callback = commands,
  })

  -- OptionSet doesn't fire on startup, so check if diff is set
  commands()
end

return M
