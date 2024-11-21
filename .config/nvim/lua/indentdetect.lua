local M = {}

local function ignore(ts)
  local syntax = ''
  if ts then
    local ok, result = pcall(function() vim.treesitter.get_node():type() end)
    if ok and result then
      syntax = result
    end
  end

  if syntax == '' then
    local line = vim.fn.line('.')
    local col = vim.fn.col('.')
    local synid = vim.fn.synIDtrans(vim.fn.synID(line, col, 1))
    syntax = vim.fn.synIDattr(synid, "name")
  end

  if string.find(syntax, 'comment', 1, true) ~= nil then
    return true
  end
  if string.find(syntax, 'string', 1, true) ~= nil then
    return true
  end
  return false
end

local function set(modeline, opt, value)
  if not vim.list_contains(modeline, opt) and vim.bo[opt] ~= value then
    vim.bo[opt] = value

    -- if softtabstop is set, make sure it mirrors the new tabstop value so
    -- that backspacing over auto inserted indentation works as expected.
    if opt == 'tabstop' and vim.o.softtabstop ~= 0 then
      vim.bo.softtabstop = vim.bo.tabstop
    end
  end
end

local function settings(settings_pairs, modeline)
  local found = false
  if settings_pairs then
    local path = vim.fn.expand('%:p')
    for key, opts in pairs(settings_pairs) do
      key = vim.fn.expand(key)
      local matched = vim.fn.substitute(path, '^' .. key, '', '') ~= path
      if matched then
        found = true
        set(modeline, 'tabstop', opts.tabstop or vim.o.tabstop)
        set(modeline, 'shiftwidth', opts.shiftwidth or vim.o.shiftwidth)
      end
    end
  end
  return found
end

local function detect()
  -- the file may be set as txt first, which we'll ignore.
  if vim.o.ft == 'txt' then
    return
  end

  local options = {'expandtab', 'shiftwidth', 'tabstop'}
  local modeline = {}

  -- check for modeline settings to prevent overriding them
  if vim.o.modeline then
    for _, option in ipairs(options) do
      vim.cmd('redir => b:indent_lastset')
      vim.cmd('silent verbose set ' .. option .. '?')
      vim.cmd('redir END')
      if string.find(vim.b.indent_lastset, 'modeline', 1, true) ~= nil then
        modeline[#modeline + 1] = option
      end
      vim.api.nvim_buf_del_var(0, 'indent_lastset')
    end
  end

  -- exit if all options have been set in the modeline
  if #modeline == #options then
    return
  end

  -- look for configured forced options
  if settings(vim.g.indent_detect_force, modeline) then
    return
  end

  local pos = vim.fn.getpos('.')
  local samples = {}
  local num_samples = 0
  local last_indent = 0
  local ts = vim.treesitter.highlighter.active[vim.fn.bufnr()] ~= nil
  vim.fn.cursor(1, 1)
  while num_samples < 5 and vim.fn.search('^\\s\\+\\S', 'eW', 500, 500) ~= 0 do
    if not ignore(ts) then
      local indent = vim.fn.indent(vim.fn.line('.'))

      -- indents larger than the previous are probably line continuations, etc.
      if last_indent == 0 or indent <= last_indent then
        -- if the indent is greater than 4, then we are probably not on a
        -- standard indent line.
        if indent <= 4 then
          local sample = samples[indent] or {}
          samples[indent] = {
            line = sample.line or vim.fn.getline('.'),
            count = (sample.count or 0) + 1,
          }
          num_samples = num_samples + 1
          last_indent = indent
        end
      end
    end
  end
  vim.fn.setpos('.', pos)

  -- find the indent with the most number of samples and use that
  local indent = vim.o.shiftwidth
  local max_samples = nil
  local sample = nil
  for ind, smpl in pairs(samples) do
    if not max_samples or smpl.count > max_samples then
      indent = ind
      sample = smpl
      max_samples = sample.count
    end
  end

  if sample then
    if sample.line:match('^\t') then
      set(modeline, 'expandtab', false)
    end
    set(modeline, 'tabstop', indent)
    set(modeline, 'shiftwidth', indent)
  else
    settings(vim.g.indent_detect_defaults, modeline)
  end
end

M.init = function()
  vim.api.nvim_create_autocmd('BufWinEnter', { pattern = '*', callback = detect })
end

return M
