local M = {}

-- get the path to our per lang regex impls
local path = debug.getinfo(1, 'S').source:sub(2, -5)
local augroup = vim.api.nvim_create_augroup('regex', {})

local patterns = function(offsets, match)
  -- vim (as of 7 beta 2) doesn't seem to be handling multiline matches very
  -- well (highlighting can get lost while scrolling), so here we break them up.
  local start, end_ = match:match('(%d+)-(%d+)')
  local start_line, start_col = offsets:pos(tonumber(start))
  local end_line, end_col = offsets:pos(tonumber(end_))

  local patterns = {}
  local hi_pattern = '\\%<sl>l\\%<sc>c\\_.*\\%<el>l\\%<ec>c'

  if start_line < end_line then
    while start_line < end_line do
      -- ignore virtual sections.
      if start_col <= #vim.fn.getline(start_line) then
        local pattern = hi_pattern
        pattern = pattern:gsub('<sl>', start_line)
        pattern = pattern:gsub('<sc>', start_col)
        pattern = pattern:gsub('<el>', start_line)
        pattern = pattern:gsub('<ec>', tostring(#vim.fn.getline(start_line) + 1))
        patterns[#patterns + 1] = pattern
      end
      start_line = start_line + 1
      start_col = 1
    end

    local pattern = hi_pattern
    pattern = pattern:gsub('<sl>', end_line)
    pattern = pattern:gsub('<sc>', '1')
    pattern = pattern:gsub('<el>', end_line)
    pattern = pattern:gsub('<ec>', end_col + 1)
    patterns[#patterns + 1] = pattern
  else
    local pattern = hi_pattern
    pattern = pattern:gsub('<sl>', start_line)
    pattern = pattern:gsub('<sc>', start_col)
    pattern = pattern:gsub('<el>', end_line)
    pattern = pattern:gsub('<ec>', end_col + 1)
    patterns[#patterns + 1] = pattern
  end

  return patterns
end

local hi = function(offsets, match, match_index, is_group)
  for _, pattern in ipairs(patterns(offsets, match)) do
    local hi = (is_group and 'RegexGroup' or 'Regex')
    hi = hi .. math.fmod(match_index, 2)
    vim.cmd(
      'syntax match ' .. hi .. ' /' .. pattern .. '/ ' ..
      'contains=RegexGroup0,RegexGroup1'
    )
  end
end

local offsets = function(file)
  local result = {offsets = {}}

  result.offsets[1] = 0

  local offset = 0
  for _, line in ipairs(vim.fn.readfile(file, 'b')) do
    offset = offset + #line + 1
    result.offsets[#result.offsets + 1] = offset
  end

  function result:pos(offset) ---@diagnostic disable-line: redefined-local
    if offset <= 0 then
      return 1, 1
    end

    local bot = 0
    local top = #self.offsets
    while (top - bot) > 1 do
      local mid = math.ceil((top + bot) / 2)
      if self.offsets[mid] < offset then
        bot = mid
      else
        top = mid
      end
    end

    if self.offsets[top] > offset then
      top = top - 1
    end

    local line = top
    local col = 1 + offset - self.offsets[top]
    return line, col
  end

  return result
end

local eval = function()
  if vim.fn.line('$') == 1 and vim.fn.getline('$') == '' then
    vim.fn.append(1, {
      'te(st)',
      'Some test content used to test',
      'language specific regex against.',
    })
    vim.cmd('1,1delete _')
    vim.bo.modified = false
  end

  -- forces reset of syntax
  vim.cmd('set ft=regex')

  if vim.b.regex_compile and not vim.b.regex_compiled then
    local compile_cmd = vim.b.regex_compile
    compile_cmd = compile_cmd:gsub('<file>', vim.b.regex_script)
    local result = vim.fn.system(compile_cmd)
    if vim.v.shell_error ~= 0 then
      vim.api.nvim_echo(
        {
          { 'Error compiling regex script:\n', 'Error' },
          { result, 'Normal' },
        }, false, {}
      )
      return
    end
    vim.b.regex_compiled = true
  end

  local cmd = vim.b.regex_execute
  local script_path = vim.fn.fnamemodify(vim.b.regex_script, ':p:h')
  cmd = cmd:gsub('<path>', script_path)
  cmd = cmd:gsub('<script>', vim.b.regex_script)
  cmd = cmd:gsub('<file>', vim.fn.bufname())
  cmd = cmd:gsub('<flags>', vim.b.regex_flags)
  local results = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo(
      {
        { 'Error executing regex script:\n', 'Error' },
        { results, 'Normal' },
      }, false, {}
    )
    return
  end

  results = vim.fn.split(results, '\n')

  ---@diagnostic disable-next-line: redefined-local
  local offsets = offsets(vim.fn.bufname())
  local match_index = 0
  for _ , result in ipairs(results) do
    local groups = vim.fn.split(result, ',')
    local group_index = 0
    if #groups > 1 then
      for _, group in ipairs(vim.list_slice(groups, 2, #groups)) do
        hi(offsets, group, group_index, true)
        group_index = group_index + 1
      end
    end

    local match = groups[1]
    hi(offsets, match, match_index)
    match_index = match_index + 1
  end

  vim.b.regex_results = results
end

local flag_toggle = function()
  local line = vim.fn.getline('.')
  if line:match('^[x ] %([mid]%)') then
    local value = line:match('^x') and ' ' or 'x'
    vim.bo.modifiable = true
    vim.fn.setline(vim.fn.line('.'), value .. line:sub(2))
    vim.bo.modifiable = false
  end

  local lines = vim.tbl_filter(
    function(l) return l:match('^x %([mid]%)') end,
    ---@diagnostic disable-next-line: param-type-mismatch
    vim.fn.getline(1, vim.fn.line('$'))
  )
  local flags = vim.tbl_map(
    function(l) return l:match('^x %(([mid])%)') end,
    lines
  )

  vim.b[vim.b.regex_buffer].regex_flags = vim.fn.join(flags, '')

  local winnr = vim.fn.bufwinnr(vim.b.regex_buffer)
  if winnr ~= -1 then
    local curwinnr = vim.fn.winnr()
    vim.cmd(winnr .. 'winc w')
    eval()
    vim.cmd(curwinnr .. 'winc w')
  end
end

local function flags(action)
  local winnr = vim.fn.bufwinnr('RegexFlags')
  if winnr ~= -1 then
    vim.cmd(winnr .. 'winc w')
    local regex_buffer = vim.b.regex_buffer
    vim.cmd('bdelete')
    vim.cmd(vim.fn.bufwinnr(regex_buffer) .. 'winc w')
    return
  end

  if action == 'close' then
    return
  end

  local regex_flags = vim.b.regex_flags
  local regex_buffer = vim.fn.bufnr('%')

  vim.cmd('vertical rightb 50new RegexFlags')

  vim.bo.modifiable = true
  vim.fn.append(1, {
    'Toggle regex compile flags using <cr>.',
    '',
    (regex_flags:match('m') and 'x' or ' ') .. ' (m) multiline',
    (regex_flags:match('i') and 'x' or ' ') .. ' (i) ignore case',
    (regex_flags:match('d') and 'x' or ' ') .. ' (d) dotall',
  })
  vim.cmd('1,1delete _')

  vim.b.regex_buffer = regex_buffer
  vim.bo.buftype = 'nofile'
  vim.bo.modifiable = false
  vim.wo.number = false
  vim.wo.winfixwidth = true
  vim.wo.statusline = '%<%f'

  vim.keymap.set('n', '<c-f>', flags, {buffer = true})
  vim.keymap.set('n', '<cr>', flag_toggle, {buffer = true})
  vim.keymap.set('n', 'u', '<Nop>', {buffer = true})
  vim.keymap.set('n', 'U', '<Nop>', {buffer = true})
  vim.keymap.set('n', '<c-r>', '<Nop>', {buffer = true})
end

local open = function(opts)
  local ft = opts.args ~= '' and opts.args or vim.bo.ft
  local script_path = path .. '/' .. ft
  if vim.fn.isdirectory(script_path) == 0 then
    vim.api.nvim_echo(
      {{ 'Regex directory not found: ' .. script_path, 'Error' }}, false, {}
    )
    return
  end

  local script
  local possibles = {
    script_path .. '/regex.' .. ft,
    script_path .. '/regex.*',
  }
  for _, possible in ipairs(possibles) do
    local found = vim.fn.glob(possible)
    if found ~= '' then
      script = vim.fn.resolve(found)
      break
    end
  end

  local compile
  local execute
  if not script then
    vim.api.nvim_echo(
      {{ 'Regex script not found in: ' .. script_path, 'Error' }}, false, {}
    )
    return
  else
    local shortmess = vim.opt.shortmess
    vim.opt.shortmess:append('A')
    local script_bufnr = vim.fn.bufadd(script)
    vim.fn.bufload(script_bufnr)
    vim.opt.shortmess = shortmess

    local comment = vim.bo[script_bufnr].commentstring
    local cl, cr = comment:match('^(.-)%%s(.-)$')
    cl = vim.trim(cl)
    cr = vim.trim(cr)

    local headers = vim.fn.getbufline(script_bufnr, 1, 2)
    for _, header in ipairs(headers) do
      local match = header:match('^' .. cl .. '%s*execute:%s*(.*)' .. cr)
      if match then
        execute = match
      else
        match = header:match('^' .. cl .. '%s*compile:%s*(.*)' .. cr)
        if match then
          compile = match
        end
      end
    end

    if not execute then
      vim.api.nvim_echo(
        {{ 'Regex script missing execute header: ' .. script, 'Error' }},
        false,
        {}
      )
      return
    end
  end

  local file = '/tmp/regex_' .. ft
  local winnr = vim.fn.bufwinnr(file)
  if winnr == -1 then
    vim.cmd('keepalt botright 10split ' .. file)
    vim.bo.ft = 'regex'
    vim.bo.bufhidden = 'wipe'
    vim.bo.buflisted = false
    vim.wo.winfixheight = true
    vim.wo.statusline = '%<%f %M %=%-10.(%l,%c%V flags=%{b:regex_flags}%) %P'

    vim.b.regex_flags = 'm' -- default multiline on
    vim.b.regex_script = script
    vim.b.regex_compile = compile
    vim.b.regex_execute = execute

    vim.keymap.set('n', '<c-f>', flags, {buffer = true})

    vim.api.nvim_create_autocmd('BufWritePost', {
      buffer = vim.fn.bufnr(),
      group = augroup,
      callback = eval,
    })
    vim.api.nvim_create_autocmd('BufWinLeave', {
      buffer = vim.fn.bufnr(),
      group = augroup,
      callback = function() flags('close') end,
    })
  else
    vim.cmd(winnr .. 'winc w')
  end

  vim.cmd('nohlsearch | noautocmd write')
  eval()
end

M.init = function()
  vim.api.nvim_create_user_command('Regex', open, { nargs = '?' })
  vim.keymap.set('ca', 'regex', function()
    local abbrev = 'regex'
    local type = vim.fn.getcmdtype()
    local pos = vim.fn.getcmdpos()
    local cmdl = vim.fn.getcmdline():sub(1, pos)
    ---@diagnostic disable-next-line: redundant-parameter
    local char = vim.fn.nr2char(vim.fn.getchar(1))
    if type == ':' and char:match('[%s\r]') and cmdl == abbrev then
      return 'Regex'
    end
    return abbrev
  end, { expr = true })
end

return M
