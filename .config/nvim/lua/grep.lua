local M = {}
local rg_options = {
  '--smart-case',
  '--case-sensitive',
  '--ignore-case',
  '--invert-match',
  '--fixed-strings',
  '--line-regexp',
  '--word-regexp',
  '--multiline',
  '--multiline-dotall',
  '--follow',
  '--hidden',
  '--no-ignore',
  '--glob GLOB',
  '-g GLOB',
}

local echo = function(message, highlight)
  vim.api.nvim_echo({{ message, highlight }}, true, {})
end

local parse = function(rawargs)
  rawargs = vim.fn.substitute(rawargs, '\\\\[<>]', '\\\\b', 'g')
  rawargs = vim.fn.substitute(rawargs, '\\\\{-}', '*?', 'g')
  local arglist = vim.fn.split(rawargs, ' ')
  local quoted = ''
  local escaped = false
  local args = {}
  for _, arg in ipairs(arglist) do
    if quoted ~= '' then
      args[#args] = args[#args] .. ' ' .. arg
      -- closing quote while in 'quoted' state, strip it off if not escaped
      if arg:match(quoted .. '$') ~= nil and
         string.sub(arg, #arg - 1, -2) ~= '\\'
      then
        quoted = ''
        args[#args] = string.sub(args[#args], 1, -2)
      end
    elseif escaped then
      args[#args] = args[#args] .. ' ' .. arg
      escaped = arg:match('\\$') ~= nil
    else
      escaped = arg:match('\\$') ~= nil
      quoted = arg:match('^[\'"]') ~= nil and string.sub(arg, 1, 1) or ''
      -- a lone quote, so must have been a quote with n spaces
      if arg == quoted then
        args[#args + 1] = ''

      -- fully quoted or not quoted at all
      elseif arg:match(quoted .. '$') ~= nil then
        quoted = ''
        args[#args + 1] = arg

      -- starting quote only, assuming quoted because of spaces
      else
        args[#args + 1] = string.sub(arg, 2, -1)
      end
    end
  end
  return args
end

local option_has_arg = function(option)
  local escaped = string.gsub(option, '%-', '%%-')
  for _, o in ipairs(rg_options) do
    if o:match('^' .. escaped .. '%W*') ~= nil then
      return o ~= option
    end
  end
  return false
end

local options_args = function(pargs)
  local options = {}
  local args = {}
  local prevarg = ''
  for _, arg in ipairs(pargs) do
    if prevarg:match('^%-') ~= nil and option_has_arg(prevarg) then
      options[#options + 1] = arg
      prevarg = arg
    elseif arg:match('^%-') ~= nil then
      options[#options + 1] = arg
      prevarg = arg
    else
      args[#args + 1] = arg
      prevarg = ''
    end
  end
  return {options, args}
end

local qf_restore = function()
  local ok, err = pcall(function() vim.cmd('silent colder') end)
  -- if we are at the bottom of the stack, then clear our results
  if not ok and err ~= nil and err:match(':E380:') then
    vim.fn.setqflist({}, 'r')
    vim.fn.setqflist({}, 'a', { title = '' })
  end
end

local grep = function(opts, args, action, suppress_messages)
  -- search hidden files, excluding .git dir
  local cmd = 'grep --sort=path --hidden --glob \'!.git\''
  local files = false
  for _, arg in ipairs(args) do
    if arg == '--files' then
      files = true
    end

    arg = vim.fn.escape(arg, '"')
    if arg:match('^%-') == nil then
      -- escape vim expansion chars
      arg = vim.fn.escape(arg, '#%')
      arg = '"' .. arg .. '"'
    end
    cmd = cmd .. ' ' .. arg
  end

  -- temporarily update the grepformat for file searches
  if files then
    local grepformat = vim.o.grepformat
    vim.api.nvim_create_autocmd('QuickFixCmdPost', {
      pattern = 'grep',
      once = true,
      callback = function() vim.o.grepformat = grepformat end,
    })
    vim.o.grepformat = '%-GERR:%.%#,%f,%-G%.%#'
  end

  -- if the current file is outside of the current work directory, then attempt
  -- to locate the project root and grep that directory
  local cwd = vim.fn.getcwd()
  local buf = vim.fn.fnamemodify(vim.fn.bufname(), ':p')
  if not string.find(buf, cwd, 1, true) then
    local git = vim.fn.finddir('.git', vim.fn.fnamemodify(buf, ':h') .. ';')
    if git ~= '' then
      cmd = cmd .. ' ' .. vim.fn.fnamemodify(git, ':h')
    end
  end

  vim.cmd('silent ' .. cmd)

  local results = vim.fn.getqflist()
  if #results == 0 then
    if files then
      qf_restore()
    end
    if not suppress_messages then
      echo('No results found: ' .. cmd, 'WarningMsg')
    end
    return false
  end

  if files then
    -- if this is a file search and there is only 1 result, then open it and
    -- restore any previous quickfix results
    if #results == 1 then
      if action == nil and opts.bang then
        action = 'split'
      end
      if action and action ~= 'edit' then
        vim.cmd('silent exec "normal! \\<c-o>"')
        vim.cmd(action)
        vim.cmd('buffer' .. results[1]['bufnr'])
      end

      -- restore  the previous quickfix results if any
      qf_restore()

    -- if the user doesn't want to jump to the first result and there are
    -- multiple results, then return the user to where they were and open the
    -- quickfix window for the user to choose the file from
    elseif opts.bang then
      vim.cmd('silent exec "normal! \\<c-o>"')
      vim.cmd('copen')
    end

  elseif not opts.bang then
    -- open up the fold on the first result
    vim.cmd('normal! zv')

    -- allow any messages, etc to fire
    vim.cmd('doautocmd CursorMoved')
    vim.cmd('doautocmd CursorHold')

  else
    -- if the user doesn't want to jump to the first result, then navigate back
    -- to where they were (cexpr! just ignores changes to the current file, so
    -- we need to use the jumplist) and open the quickfix window.
    vim.cmd('silent exec "normal! \\<c-o>"')
    vim.cmd('copen')
  end
  return true
end

M.find = function(opts)
  if vim.o.grepprg:match('^rg%w*') == nil then
    echo('grepprg must be set to ripgrep (rg).', 'Error')
    return
  end

  if vim.fn.bufname():match('^%.%./') then
    echo(
      'Attempting to grep from a file outside of the current working directory',
      'Error'
    )
    return
  end

  if opts.args == '' then
    local cword = vim.fn.expand('<cword>')
    if cword == '' then
      cword = vim.fn.getreg('/')
    end
    if cword == '' then
      echo('No word under the cursor to search for.', 'Error')
      return
    end
    opts.args = '\\<' .. cword .. '\\>'

    if vim.fn.histget('cmd', -1) == 'Grep' then
      vim.fn.histdel('cmd', -1)
      vim.fn.histadd('cmd', 'Grep ' .. opts.args)
    end
  elseif opts.args == '--files' then
    local uri = vim.fn.substitute(
      vim.fn.getline('.'),
       "\\(.*[[:space:]\"',(\\[{><]\\|^\\)\\(.*\\%" ..
       vim.fn.col('.') ..
       "c.\\{-}\\)\\([[:space:]\"',)\\]}<>].*\\|$\\)",
       '\\2',
       ''
    )
    opts.args = opts.args .. ' -g **/' .. uri
  end

  local args = parse(opts.args)
  local result = options_args(args)
  local options = result[1]
  -- if pattern and dir supplied, see if dir is a glob pattern
  if #result[2] == 2 then
    options[#options + 1] = '-g'
    options[#options + 1] = result[2][2]
    options[#options + 1] = '-e'
    options[#options + 1] = result[2][1]
    args = options
  end

  grep(opts, args)
end

M.find_file = function(path, cmd)
  -- A helper function that other scripts can use to locate a file by path
  return grep({ bang = true }, {'--files', '-g', '**/' .. path}, cmd, true)
end

M.complete = function(lead, cmdl, pos)
  local pre = vim.fn.substitute(string.sub(cmdl, 1, pos), '\\w\\+\\s\\+', '', '')
  local args = parse(pre)

  -- complete rg options
  if lead:match('^%-') then
    -- return filter(copy(s:supported_options), 'v:val =~# "^" . lead')
    local options = {}
    for _, opt in ipairs(rg_options) do
      if opt:match('^' .. string.gsub(lead, '%-', '%%-')) then
        options[#options + 1] = opt
      end
    end
    return options
  end

  -- rg option with an arg
  if #args ~= 0 and args[#args]:match('^%-') and option_has_arg(args[#args]) then
    return {}
  end

  -- complete patterns from search history
  local result = options_args(args)
  args = result[2]
  if #args == 0 or (#args == 1 and lead ~= '') then
    local search = {}
    local i = -1
    while i >= -10 do
      local hist = vim.fn.histget('search', i)
      if hist == '' then
        break
      end
      -- hist = vim.fn.substitute(hist, '\\([^\\]\\)\\s', '\1\\ ', 'g')
      search[#search + 1] = hist
      i = i - 1
    end
    local results = {}
    for _, hist in ipairs(search) do
      local found = string.find(hist, lead, 1, false)
      if found == 1 then
        results[#results + 1] = hist
      end
    end
    return results
  end

  -- complete absolute / cwd relative files/directories
  local paths = vim.fn.glob(lead .. '*', false, true)
  local results = {}
  for _, path in ipairs(paths) do
    if vim.fn.isdirectory(vim.fn.fnamemodify(path, ':p')) == 1 then
      path = path .. '/'
    end
    results[#results + 1] = path
  end
  return results
end

return M
