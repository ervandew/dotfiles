local git = require('git')

local window = function(name, lines)
  local winnr = vim.fn.bufwinnr(name)
  if winnr ~= -1 then
    vim.cmd(winnr .. 'winc w')
  else
    vim.cmd('belowright new ' .. vim.fn.escape(name, ''))
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
      open = 'belowright sview',
    })

  elseif added then
    local result = git.git('show ":' .. path .. '"')
    if not result then
      return
    end
    window(path, vim.fn.split(result, '\n'))

  else
    local diff_cmd = 'diff ' .. (unstaged and '' or '--cached ')
    local result = git.git(diff_cmd .. '"' .. path .. '"')
    if not result then
      return
    end
    window(path .. '.patch', vim.fn.split(result, '\n'))
  end

  vim.api.nvim_create_autocmd('BufEnter', {
    buffer = vim.fn.bufnr(),
    callback = function()
      -- if nothing but differ buffers are open, then close the editor.
      local winnr = 1 ---@diagnostic disable-line: redefined-local
      while winnr <= vim.fn.winnr('$') do
        local bufnr = vim.fn.winbufnr(winnr)
        if vim.bo[bufnr].ft ~= 'gitcommit' then
          vim.cmd(bufnr .. 'bdelete')
        else
          winnr = winnr + 1
        end
      end
      vim.cmd.quitall()
    end,
  })
end

-- prevent lsp servers from starting when viewing files
vim.g.lsp_disabled = true

vim.keymap.set('n', '<cr>', view, { buffer = true })
