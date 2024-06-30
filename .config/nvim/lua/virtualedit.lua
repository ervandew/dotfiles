vim.opt.virtualedit = 'all'

local M = {}

local function insert(key)
  -- when starting insert on an empty line, start it at the correct indent
  if #vim.fn.getline('.') == 0 and vim.fn.line('$') ~= 1 then
    return vim.fn.line('.') == vim.fn.line('$') and 'ddo' or 'ddO'
  end
  return (vim.fn.virtcol('.') > vim.fn.col('$') and '$' or '') .. key
end

local function paste()
  -- we need this command for accpeting a count in the paste expression
  -- (using :set in the resulting expression would otherwise prevent that)
  vim.api.nvim_create_user_command('TempVEDisable', function()
    vim.o.ve = ''
    vim.api.nvim_del_user_command('TempVEDisable')
  end, { count = 1 })
  local count = vim.v.count > 0 and vim.v.count or ''
  local register = vim.v.register ~= '"' and ('"' .. vim.v.register) or ''
  local disable = ':TempVEDisable<cr>'
  local restore = ':set ve=' .. vim.o.ve .. '<cr>'
  return disable .. count .. register .. 'p' .. restore
end

M.mappings = function()
  -- virtualedit mappings to start insert no farther than the end of the actual
  -- line
  vim.keymap.set('n', 'a', function() return insert('a') end, { expr = true })
  vim.keymap.set('n', 'i', function() return insert('i') end, { expr = true })

  -- temporarily disable virtual edit to avoid pasting past the end of the line
  vim.keymap.set('n', 'p', paste, { expr = true, silent = true })
end

return M
