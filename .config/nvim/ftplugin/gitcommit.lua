local git = require('git')

local window = function(name, lines, open)
  local winnr = vim.fn.bufwinnr(name)
  if winnr ~= -1 then
    vim.cmd(winnr .. 'winc w')
  else
    open = open or 'belowright new'
    vim.cmd(open .. ' ' .. vim.fn.escape(name, ''))
    vim.keymap.set('n', 'q', function()
      vim.cmd.quit()
      vim.cmd.doautocmd('WinEnter')
    end, { buffer = true })
  end

  vim.bo.readonly = false
  vim.bo.modifiable = true
  vim.cmd('silent 1,$delete _')
  vim.fn.append(1, lines)
  vim.cmd('silent 1,1delete _')
  vim.fn.cursor(1, 1)
  vim.bo.modified = false
  vim.bo.readonly = true
  vim.bo.modifiable = false
  vim.bo.swapfile = false
  vim.bo.buflisted = false
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
end

local diff_augroup = vim.api.nvim_create_augroup('git_commit_diff', {})
local view = function()
  local path
  local added = false
  local deleted = false
  local unstaged = false
  local line = vim.fn.getline('.')
  if line:match('^#%s*modified:.*') then
    path = line:match('^#%s*modified:%s+(.*)%s*')
    local section_lnum = vim.fn.search('#\\s\\+Change[sd]\\>.*:$', 'bnW')
    if section_lnum ~= 0 then
      local section = vim.fn.getline(section_lnum)
      unstaged = section == '# Changes not staged for commit:'
    end
  elseif line:match('^#%s*new file:.*') then
    path = line:match('^#%s*new file:%s+(.*)%s*')
    added = true
  elseif line:match('^#%s*deleted:.*') then
    path = line:match('^#%s*deleted:%s+(.*)%s*')
    deleted = true
  end

  if not path then
    return
  end

  local winnr = 1
  while winnr <= vim.fn.winnr('$') do
    local bufnr = vim.fn.winbufnr(winnr)
    if vim.bo[bufnr].ft ~= 'gitcommit' then
      vim.cmd(bufnr .. 'bdelete')
    else
      winnr = winnr + 1
    end
  end

  local revision = git.git(
    'rev-list --abbrev-commit -n 1 HEAD -- ' .. '"' .. path .. '"'
  )
  if deleted then
    if not revision then
      vim.api.nvim_echo({{ 'Unable to find a revision.', 'Error' }}, true, {})
      return
    end

    git.show({
      path = path,
      revision = revision,
      open = 'belowright new',
    })

  elseif added then
    local result = git.git('show ":' .. path .. '"')
    if not result then
      return
    end
    window(path, vim.fn.split(result, '\n'))

  elseif unstaged then
    local result = git.git('diff "' .. path .. '"')
    if not result then
      return
    end
    window(path .. '.patch', vim.fn.split(result, '\n'))
  else
    local staged = git.git('show ":' .. path .. '"')
    if not staged then
      return
    end

    window(
      'git_staged_' .. vim.fn.fnamemodify(path, ':t'),
      vim.fn.split(staged, '\n')
    )
    local bufnr = vim.fn.bufnr('%')
    local shown = git.show({
      path = path,
      revision = revision,
      open = 'rightbelow vnew',
    })
    if shown then
      local diffbufnr = vim.fn.bufnr()
      vim.cmd.diffthis()

      vim.cmd.winc('p')
      vim.cmd.diffthis()
      vim.api.nvim_clear_autocmds({ buffer = bufnr, group = diff_augroup })
      vim.api.nvim_create_autocmd('BufWinLeave', {
        buffer = bufnr,
        group = diff_augroup,
        callback = function()
          vim.cmd('silent! bdelete ' .. diffbufnr)
        end,
      })
    end
  end

  vim.api.nvim_create_autocmd('BufEnter', {
    buffer = vim.fn.bufnr(),
    callback = function()
      -- if nothing but diff buffers are open, then close the editor.
      local winnr = 1 ---@diagnostic disable-line: redefined-local
      while winnr <= vim.fn.winnr('$') do
        local bufnr = vim.fn.winbufnr(winnr)
        if vim.bo[bufnr].ft == 'gitcommit' then
          return
        end
        winnr = winnr + 1
      end
      vim.cmd.quitall()
    end,
  })
end

-- prevent lsp servers from starting when viewing files
vim.g.lsp_disabled = true

vim.keymap.set('n', '<cr>', view, { buffer = true })
