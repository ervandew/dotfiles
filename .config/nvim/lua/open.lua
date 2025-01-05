local M = {}

local is_absolute = function(path)
  return path:match('^~?/') ~= nil
end

local is_dir = function(path)
  return vim.fn.isdirectory(vim.fn.fnamemodify(path, ':p')) == 1
end

local file_readable = function(path)
  return vim.fn.filereadable(path) == 1
end

local error = function(msg)
  vim.api.nvim_echo({{ msg, 'Error' }}, false, {})
end

local prompt = function(msg)
  local ok, choice = pcall(
    vim.fn.input,
    msg .. '\n' ..
    '[a]bsolute or [r]elative: '
  )
  if ok and choice:match('^[ar]$') then
    return choice
  end
end

M.complete = function(lead)
  local abs_only = lead:match('^%./') -- force only absolute results
  local rel_only = lead:match('^%%/') -- force only relative results
  local results = {}
  local add = function(path, entry)
    if is_dir(path) then
      entry = entry .. '/'
    end
    if not vim.list_contains(results, entry) then
      results[#results + 1] = entry
    end
  end

  if not rel_only then
    local cwd_paths = vim.fn.glob(lead .. '*', false, true)
    for _, path in ipairs(cwd_paths) do
      add(path, path)
    end
  end

  if not abs_only and not is_absolute(lead) then
    if rel_only then
      lead = string.sub(lead, 3)
    end
    local file_dir = vim.fn.fnamemodify(vim.fn.bufname(), ':h')
    if file_dir ~= '.' and file_dir ~= vim.fn.getcwd() then
      local rel_paths = vim.fn.glob(file_dir .. '/' .. lead .. '*', false, true)
      for _, path in ipairs(rel_paths) do
        add(path, string.sub(path, #file_dir + 2))
      end
      table.sort(results)
    end
  end
  return results
end

M.open = function(action, opts)
  local path = opts.args
  if path == '' then
    vim.cmd(action)
    return
  end

  local rel_dir = vim.fn.fnamemodify(vim.fn.bufname(), ':h')
  local rel_path
  if not is_absolute(path) and rel_dir ~= '.' then
    rel_path = vim.fn.resolve(vim.fn.fnamemodify(rel_dir .. '/' .. path, ':p'))
  end

  if is_dir(path) or is_dir(rel_path) then
    error('Attempting to open a directory')
    return
  end

  path = vim.fn.resolve(vim.fn.fnamemodify(path, ':p'))
  -- path found at cwd and rel path, so prompt for which to open
  if path ~= rel_path and file_readable(path) and file_readable(rel_path) then
    local choice = prompt(
      'multiple results:\n' ..
      '  absolute: ' .. path .. '\n' ..
      '  relative: ' .. rel_path
    )
    if not choice then
      return
    elseif choice == 'r' then
      path = rel_path
    end
  elseif file_readable(path) then
    path = path
  elseif file_readable(rel_path) then
    path = rel_path
  -- new file, check whether to open at cwd or relative path
  elseif rel_path then
    local dir = vim.fn.fnamemodify(opts.args, ':h')
    local cwd_exists = is_dir(dir)
    local rel_exists = rel_dir ~= '.' and is_dir(rel_dir .. '/' .. dir)
    if cwd_exists and rel_exists then
      local choice = prompt('open new file: ' .. opts.args)
      if not choice then
        return
      elseif choice == 'r' then
        path = rel_path
      end
    elseif cwd_exists then
      path = path
    elseif rel_exists then
      path = rel_path
    else
      error('Directory not found: ' .. dir)
      return
    end
  end

  vim.cmd(action .. ' ' .. vim.fn.fnamemodify(path, ':.'))
end

M.init = function()
  local commands = { E = 'edit', R = 'read', S = 'split' }
  for command, action in pairs(commands) do
    vim.api.nvim_create_user_command(
      command,
      function(opts) M.open(action, opts) end,
      { nargs = '?', complete = M.complete }
    )
  end

  local abbrevs = { 'e', 'edit', 'r', 'read', 's', 'split' }
  for _, abbrev in ipairs(abbrevs) do
    vim.keymap.set('ca', abbrev, function()
      local type = vim.fn.getcmdtype()
      local pos = vim.fn.getcmdpos()
      ---@diagnostic disable-next-line: redundant-parameter
      local char = vim.fn.nr2char(vim.fn.getchar(1))
      if type == ':' and pos == #abbrev + 1 and char:match('[%s]') then
        return abbrev:sub(1, 1):upper()
      end
      return abbrev
    end, { expr = true })
  end
end

return M
