local M = {}

local termcodes = function(char)
  return vim.api.nvim_replace_termcodes(char, true, false, true)
end

local key = function(dir)
  local line = vim.fn.getline('.')
  local col = vim.fn.col('.')
  local pre = string.sub(line, 1, col - 1)
  if pre == '' or string.match(pre, '%s$') then
    return termcodes('<tab>')
  end

  -- already in completion mode, so just return the key to nav up/down the list
  if vim.fn.pumvisible() ~= 0 then
    return termcodes('<c-' .. dir .. '>')
  end

  -- check if completing a file path
  -- avoid false positive in on '</' in html, xml, etc files
  if vim.fn.match(line, '<\\@<!/\\.\\?\\w*\\%' .. col .. 'c') ~= -1 then
    return termcodes('<c-x><c-f>')
  end

  -- check if attempting to complete a member (foo.bar, foo:bar, foo->bar)
  if vim.fn.match(line, '\\(\\.\\|:\\|->\\)\\w*\\%' .. col .. 'c') ~= -1 then
    return termcodes('<c-x><c-o>')
  end

  -- default completion
  return termcodes('<c-p>')
end

M.mappings = function()
  vim.keymap.set('i', '<tab>', function() return key('n') end, { expr = true })
  vim.keymap.set('i', '<s-tab>', function() return key('p') end, { expr = true })
end

return M
