local M = {}

local function current(list)
  local pos = vim.fn.getcurpos()
  local lnum = vim.fn.line('.')
  local open = list .. 'open'
  vim.cmd(open)
  vim.fn.cursor(1, 1)

  local found = vim.fn.search('|' .. pos[2] .. '\\>')
  if found then
    vim.cmd(vim.fn.line('.') .. list .. list)
    vim.fn.cursor(lnum, pos[2])
    vim.cmd(open)
  else
    vim.api.nvim_echo(
      {{ 'no entry found for line ' .. lnum, 'WarningMsg' }}, false, {}
    )
  end
end

local function next(list, cmd)
  local func = list  == 'c' and
    function(...) return vim.fn.getqflist(...) end or
    function(...) return vim.fn.getloclist(0, ...) end

  local error_count = #func()
  if error_count == 0 then
    vim.api.nvim_echo({{ 'no entries', 'WarningMsg' }}, false, {})
    return
  end

  -- write the file if necessary
  vim.cmd('noautocmd silent update')

  -- check new error count to handle case where writing the file modifies the
  -- results.
  local updated_error_count = #func()
  if updated_error_count ~= error_count then
     -- cc or ll (return to the current error position)
    cmd = list .. list
  end
  local cur = func({ idx = 0 })['idx']
  if cur == updated_error_count then
    vim.api.nvim_echo({{ 'no more entries', 'WarningMsg' }}, false, {})
    return
  end
  vim.cmd(cmd)
end

local function toggle(list)
  if list == 'c' then
    vim.cmd(vim.o.ft == 'qf' and 'cclose' or 'copen')
  else
    local loclist = vim.fn.getloclist(0)
    if #loclist == 0 then
      vim.api.nvim_echo({{ 'no location list', 'WarningMsg' }}, false, {})
      return
    end
    vim.cmd(vim.o.ft == 'qf' and 'lclose' or 'lopen')
  end
end

local function delete()
  local lnum = vim.fn.line('.')
  local cnum = vim.fn.col('.')
  local start = lnum
  local finish = lnum

  if vim.api.nvim_get_mode().mode == 'V' then
    local esc = vim.api.nvim_replace_termcodes('<esc>', true, false, true)
    vim.api.nvim_feedkeys(esc, 'x', false)
    start = unpack(vim.api.nvim_buf_get_mark(0, '<'))
    finish = unpack(vim.api.nvim_buf_get_mark(0, '>'))
  end

  if vim.fn.getwininfo(vim.fn.win_getid())[1].loclist == 1 then
    local props = vim.fn.getloclist(0, { all = true })
    local pre = vim.list_slice(props.items, 1, start - 1)
    local post = vim.list_slice(props.items, finish + 1)
    props.items = vim.list_extend(pre, post)
    vim.fn.setloclist(0, {}, 'r', props)
  else
    local props = vim.fn.getqflist({ all  = true })
    local pre = vim.list_slice(props.items, 1, start - 1)
    local post = vim.list_slice(props.items, finish + 1)
    props.items = vim.list_extend(pre, post)
    vim.fn.setqflist({}, 'r', props)
  end
  vim.fn.cursor(lnum, cnum)
end

local function split(close)
  local wininfo = vim.fn.getwininfo(vim.fn.win_getid())
  local type = wininfo[1].loclist == 1 and 'loc' or 'qf'
  local list = type == 'qf' and vim.fn.getqflist() or vim.fn.getloclist(0)
  local bufnum = vim.fn.bufnr()
  local entry = list[vim.fn.line('.')].bufnr
  if not vim.list_contains(vim.fn.tabpagebuflist(), entry) then
    vim.cmd('winc p')
    vim.cmd('new | buffer ' .. entry)
    vim.cmd(vim.fn.bufwinnr(bufnum) .. 'winc w')
  end

  local cr = vim.api.nvim_replace_termcodes('<cr>', true, false, true)
  vim.cmd('normal! ' .. cr)

  if close then
    vim.cmd(type == 'qf' and 'cclose' or 'lclose')
  end
end

M.init = function()
  -- toggle quickfix/location lists
  vim.keymap.set('n', '<leader>ct', function() toggle('c') end)
  vim.keymap.set('n', '<leader>lt', function() toggle('l') end)

  -- write and go to next quickfix/location list result
  vim.keymap.set('n', '<leader>cn', function() next('c', 'cnext') end)
  vim.keymap.set('n', '<leader>cf', function() next('c', 'cnfile') end)
  vim.keymap.set('n', '<leader>ln', function() next('l', 'lnext') end)

  -- open the quickfix/location list and jump to the first entry for the line
  -- under the cursor
  vim.keymap.set('n', '<leader>cc', function() current('c') end)
  vim.keymap.set('n', '<leader>ll', function() current('l') end)

  -- qf window mappings
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'qf',
    callback = function()
      local opts = { buffer = true, silent = true }
      vim.keymap.set('x', 'd',  delete, opts)
      vim.keymap.set('n', 'dd', delete, opts)
      vim.keymap.set('n', 's',  function() split(true) end, opts)
      vim.keymap.set('n', 'S',  function() split(false) end, opts)
      vim.keymap.set('n', 'q', ':close<cr>', opts)

      -- for loclist windows, auto close when associated window/buffer is closed
      local winid = vim.api.nvim_get_current_win()
      if vim.fn.getwininfo(winid)[1].loclist == 1 then
        local pwinid = vim.fn.getloclist(winid, { filewinid = 0 }).filewinid
        vim.api.nvim_create_autocmd('BufWinLeave', {
          buffer = vim.fn.winbufnr(pwinid),
          callback = function()
            vim.cmd.lclose()
          end,
          once = true,
        })
      end
    end
})
end

return M
