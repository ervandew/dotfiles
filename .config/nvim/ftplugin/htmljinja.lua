vim.keymap.set('n', '<cr>', function()
  local line = vim.fn.getline('.')
  local col = vim.fn.col('.')

  local paths = nil
  local patterns = nil

  local possible_path = vim.fn.substitute(
    line,
    "\\(.*[[:space:]\"',(\\[{><]\\|^\\)\\(.*\\%" ..
    col ..
    "c.\\{-}\\)\\([[:space:]\"',)\\]}<>].*\\|$\\)",
    '\\2',
    ''
  )
  if possible_path:match('%.css$') ~= nil then
    paths = {
      vim.fn.substitute(possible_path, '\\.css$', '.scss', ''),
      vim.fn.substitute(possible_path, '\\.css$', '/index.scss', ''),
    }
  elseif possible_path:match('%.js$') ~= nil then
    paths = {
      possible_path,
      vim.fn.substitute(possible_path, '\\.js', '/index.js', ''),
    }
  elseif possible_path:match('%.html$') ~= nil then
    paths = { possible_path }
  else
    local word = vim.fn.expand('<cword>')

    -- filter ref
    if line:match('|' .. word) ~= nil then
      patterns = { ['.py'] = '\\<def\\s+' .. word .. '\\>' }

    -- url name ref
    elseif line:match("url%s*%(['\"]" .. word) ~= nil then
      patterns = { ['.py'] = '\\<def\\s+' .. word .. '\\>' }

    -- macro ref
    elseif line:match('{%%%-?%s*call%s+' .. word) ~= nil then
      patterns = { ['.html'] = '\\<macro\\s+' .. word .. '\\>' }

    -- function or macro ref
    elseif line:match('{{%-?%s*' .. word) ~= nil then
      patterns = {
        ['.html'] = '\\<macro\\s+' .. word .. '\\>',
        ['.py'] = '\\<def\\s+' .. word .. '\\>',
      }

    -- method ref
    elseif line:match('%.' .. word .. '%s*%(') ~= nil then
      patterns = { ['.py'] = '\\<def\\s+' .. word .. '\\>' }

    -- class reference
    elseif word:match('^[A-Z]+[a-z]+') ~= nil then
      patterns = { ['.py'] = '\\<class\\s+' .. word .. '\\>' }
    end
  end

  if patterns then
    local winnum = vim.fn.winnr()
    local results, num
    for ext, pattern in pairs(patterns) do
      vim.cmd('silent Grep! ' .. pattern .. ' **/*' .. ext)
      results = vim.fn.getqflist()
      num = #results
      if num then
        break
      end
    end

    if not num then
      vim.api.nvim_echo({{ 'No result found', 'WarningMsg' }}, true, {})
    elseif num == 1 then
      vim.cmd('cclose')
      vim.cmd(winnum .. 'winc w')
      if not vim.list_contains(vim.fn.tabpagebuflist(), results[1].bufnr) then
        vim.cmd('new | buffer ' .. results[1].bufnr)
      end
      vim.cmd('cfirst')
    end
  elseif paths then
    local found = false
    for _, path in ipairs(paths) do
      found = require('grep').find_file(path, 'split')
      if found then
        break
      end
    end
    if not found then
      vim.api.nvim_echo({{ 'File not found', 'WarningMsg' }}, true, {})
    end
  end
end, { buffer = true, silent = true })
