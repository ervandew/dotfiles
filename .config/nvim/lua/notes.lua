local M = {}

local open = function(opts)
  local cwd = vim.fn.getcwd()
  local path = vim.fn.expand('~/.config/notes')

  if opts.bang then
    if vim.fn.isdirectory(path) == 0 then
      vim.fn.mkdir(path, 'p')
    end
  else
    if vim.fn.filereadable(cwd .. '/notes.md') == 1 then
      path = cwd
    end
  end

  local notes = path .. '/notes.md'

  -- convert to a relative path if it's within our cwd
  local index = string.find(notes, cwd, 1, true)
  if index == 1 then
    notes = string.sub(notes, #cwd + 2)
  end

  local winnr = vim.fn.bufwinnr(vim.fn.bufnr('^' .. notes .. '$'))
  if winnr ~= -1 then
    vim.cmd(winnr .. 'winc w')
    vim.cmd([[ normal! m' ]]) -- update jump list

  -- open the file
  else
    local cmd = 'split'
    if vim.fn.expand('%') == '' and
       not vim.o.modified and
       vim.fn.line('$') == 1 and
       vim.fn.getline(1) == ''
    then
      cmd = 'edit'
    end
    vim.cmd(cmd .. ' ' .. notes)
  end

  -- close any open folds (may no longer be relevant)
  vim.cmd('silent! normal! zM')

  if opts.args ~= '' then
    vim.fn.cursor(1, 1)
    ---@diagnostic disable-next-line: param-type-mismatch
    local ok, result = pcall(vim.cmd, '/' .. opts.args .. '\\c')
    if not ok then
      result = vim.fn.substitute(result, '.*Vim:', '', '')
      vim.api.nvim_echo({{ result, 'Error' }}, false, {})
    else
      -- open folds (z0), center the cursor line (zz)
      vim.cmd('silent! normal! zOzz')
    end
  end
end

M.init = function()
  vim.g.markdown_folding = 1 -- enable folding at headers
  vim.api.nvim_create_user_command('Notes', open, { bang = true, nargs = '*' })
  vim.keymap.set('ca', 'notes', function()
    local abbrev = 'notes'
    local type = vim.fn.getcmdtype()
    local pos = vim.fn.getcmdpos()
    ---@diagnostic disable-next-line: redundant-parameter
    local char = vim.fn.nr2char(vim.fn.getchar(1))
    if type == ':' and pos == #abbrev + 1 and (char == ' ' or char == '\r') then
      return 'Notes'
    end
    return abbrev
  end, { expr = true })
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'markdown',
    callback = function()
      local bufname = vim.fn.bufname()
      if bufname:match('notes.md$') ~= nil then
        vim.wo.foldlevel = 0
        vim.bo.tabstop = 2
        vim.bo.shiftwidth = 2
        vim.cmd('silent! normal! zM')
      end
    end,
  })
  vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter' }, {
    pattern = '*',
    callback = function()
      local bufname = vim.fn.bufname()
      if bufname:match('notes.md$') ~= nil then
        vim.o.foldclose = 'all'
      else
        vim.o.foldclose = ''
      end
    end,
  })
end

return M
