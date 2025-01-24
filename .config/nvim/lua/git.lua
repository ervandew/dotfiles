M = {}

local config
local notify = function(msg, level, opts)
  opts = opts or {}
  opts.title = opts.title or 'git'
  vim.notify(msg, level, opts)
end

local error = function(msg, hl)
  vim.api.nvim_echo({{ msg, hl or 'Error' }}, true, {})
end

local confirm = function(msg, choices, default, type)
  default = default or 0
  local ok, choice = pcall(vim.fn.confirm, msg, choices, default, type)
  return (ok and choice ~= 0) and choice or nil
end

local modal = function()
  local width = math.floor(vim.o.columns * 0.75)
  local height = math.floor(vim.o.lines * 0.75)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_open_win(bufnr, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    style = 'minimal',
    border = 'rounded',
  })
end

local term = function(cmd, opts)
  local curwin = vim.fn.winnr()
  modal()
  vim.wo.cursorline = false
  vim.wo.cursorcolumn = false
  vim.wo.number = false
  local term_bufnr = vim.fn.bufnr()
  if opts.echo then
    cmd = 'echo \\"' .. opts.echo .. '\\" ; ' .. cmd
  end
  vim.fn.termopen(vim.o.shell .. ' -c "' .. cmd .. '"', {
    cwd = opts.cwd,
    on_exit = opts.on_exit and function(_, exit_code)
      opts.on_exit(term_bufnr, exit_code)
    end or nil
  })
  vim.schedule(function()
    vim.cmd.startinsert()
    vim.api.nvim_create_autocmd('BufUnload', {
      buffer = term_bufnr,
      callback = function() vim.cmd(curwin .. 'winc w') end,
    })
    vim.keymap.set('n', 'q', function()
      vim.cmd.quit()
      vim.cmd(curwin .. 'winc w')
      vim.cmd.doautocmd('WinEnter')
    end, { buffer = term_bufnr })
  end)
end

local window = function(name, open, lines, opts)
  opts = opts or {}

  local winnr = vim.fn.bufwinnr(name)
  if winnr ~= -1 then
    vim.cmd(winnr .. 'winc w')
  else
    if open == 'modal' then
      modal()
      vim.cmd.file(name)
    else
      vim.cmd(open .. ' ' .. vim.fn.escape(name, ''))
    end

    vim.keymap.set('n', 'q', function()
      vim.cmd.quit()
      vim.cmd.doautocmd('WinEnter')
    end, { buffer = true })

    if name:match('%.patch$') then
      -- mimic standard pager scrolling
      vim.keymap.set('n', '<space>', '<c-f>', { buffer = true, nowait = true })
    end

    if type(opts.created) == 'function' then
      opts.created()
    end

    -- detach all lsp clients for this temp buffer
    local bufnr = vim.fn.bufnr()
    local clients = vim.lsp.get_clients({ buffer = bufnr })
    for _, client in ipairs(clients) do
      if vim.lsp.buf_is_attached(bufnr, client.id) then
        vim.lsp.buf_detach_client(bufnr, client.id)
      end
    end
  end

  vim.bo.readonly = false
  vim.bo.modifiable = true
  vim.cmd('silent 1,$delete _')
  vim.fn.append(1, lines)
  vim.cmd('silent 1,1delete _')
  vim.fn.cursor(1, 1)
  vim.bo.modifiable = false
  vim.bo.swapfile = false
  vim.bo.buflisted = false
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.cmd.doautocmd('BufReadPost')

  -- let nvim diff code attempt to sync the cursor position
  if opts.diff_sync then
    vim.cmd.diffthis()
    vim.cmd.winc('p')

    -- don't discrupt an existing diff
    local other_diff = vim.wo.diff
    if not other_diff then
      vim.cmd.diffthis()
    end

    -- opening the diff folds seems to be necessary, at least if the original
    -- cursor position is within one
    vim.cmd('normal zR')

    if not other_diff then
      vim.cmd.diffoff()
    else
      vim.cmd('normal zM') -- close folds we opened
    end
    vim.cmd.winc('p')
    vim.cmd.diffoff()
  end
end

M.git = function(args, opts)
  local cmd = 'git --no-pager ' .. args
  local result
  opts = opts or {}
  if opts.exec then
    local outfile = vim.fn.tempname()
    cmd = '!' .. cmd .. ' 2>&1| tee "' .. outfile .. '"'
    vim.cmd(vim.fn.escape(cmd, '%'))
    result = vim.fn.join(vim.fn.readfile(outfile), "\n")
    vim.fn.delete(outfile)
  else
    result = vim.fn.system(cmd)
  end

  if vim.v.shell_error ~= 0 or result:match('^fatal:') then
    if not opts.quiet then
      error('Error executing command: ' .. cmd .. '\n' .. result)
    end
    return
  end

  return result:gsub('\n$', '')
end

local set_info = function(root, path, revision)
  vim.b.git_info = { root = root, path = path, revision = revision }
end

local repo = function()
  if vim.b.git_info then
    return vim.b.git_info.root
  end
  local root = M.git('rev-parse --show-toplevel')
  if root then
    -- ensure we have the full path ending in a path delimiter
    root = vim.fn.fnamemodify(root, ':p')
  end
  return root
end

local repo_settings = function()
  local root = repo()
  if root then
    -- escape dashes for matching
    root = root:gsub('%-', '%%-')
    for key, settings in pairs(vim.g.git_repo_settings) do
      -- normalize the path by expanding to a full path ending in path delimiter
      key = vim.fn.fnamemodify(vim.fn.expand(key), ':p')
      if key:match('^' .. root .. '$') then
        return settings
      end
    end
  end
  return {}
end

local is_protected = function(branch)
  local protected = vim.fn.split(M.git('config get push.force.protected') or '')
  return vim.list_contains(protected, branch)
end

local get_revision = function(path, revision)
  return M.git(
    'rev-list --abbrev-commit -n 1 ' ..
    revision .. ' -- ' ..
    '"' .. path .. '"'
  )
end

local get_previous_revision = function(path, revision)
  -- NOTE: ideally this would use rev-list, but when limiting based on a
  -- previous revision, rev-list (and log) may skip some commits, and i'm
  -- unable to determine why, so the below is a bit more of a brute force method
  return M.git(
    'log --follow --pretty=tformat:%h -- ' ..
    '"' .. path .. '" |' ..
    'grep ' .. revision .. ' -A 1 | ' ..
    'tail -1'
  )
end

local file = function(path)
  local root, revision
  if not path then
    if vim.b.git_info then
      root = vim.b.git_info.root
      path = vim.b.git_info.path
      if not path then
        return
      end
      -- don't use the cached revision if we are in the actual file since there
      -- could have been additional commits since this was set (latest revision
      -- will be determined below)
      if vim.fn.resolve(vim.fn.expand('%:p')) ~= root .. path then
        revision = vim.b.git_info.revision
      end
    else
      root = repo()
      if root then
        path = vim.fn.resolve(vim.fn.expand('%:p'))
      end
    end
  else
    root = repo()
  end

  if not revision then
    revision = M.git('rev-list --abbrev-commit -n 1 HEAD -- "' .. path .. '"')
  else
    -- for following renames
    local result = M.git(
      'log ' ..
      '--pretty=tformat:"%h" ' ..
      '--name-status ' ..
      '--follow ' ..
      revision .. '~1.. -- ' ..
      '"' .. path .. '" |' ..
      'tail -1'
    )
    if not result then
      return
    end
    -- result should be something like:
    --   R096\told_path\tnew_path
    if result:match('^[AMRC]') then
      local parts = vim.fn.split(result, '\t')
      path = parts[2]
    end
  end

  if path then
    -- make relative to root (escaping any dashes in the root)
    path = path:gsub('^' .. root:gsub('%-', '%%-'), '')
  end

  return root, path, revision
end

local me = {}
local log_name = 'git log'
local status_name = 'git status'

local annotate_info = function()
  if vim.fn.mode() ~= 'n' then
    return
  end

  if not vim.b.git_annotations then
    return
  end

  local first = vim.b.git_annotations[1].lnum
  local last = vim.b.git_annotations[#vim.b.git_annotations].lnum
  local lnum = vim.fn.line('.')
  if lnum < first or lnum > last then
    return
  end

  local annotation = vim.b.git_annotations[lnum - first + 1]
  if not annotation or annotation.uncommitted then
    return
  end

  local result = M.git(
    'log "--pretty=format:%h|%ai|%an|%s" -1 ' .. annotation.revision
  )
  if not result then
    return
  end

  local parts = vim.fn.split(result, '|')
  local info = {
    version = parts[1],
    date = parts[2],
    author = parts[3],
    message = vim.fn.join(vim.list_slice(parts, 4))
  }

  local saved_ruler = vim.o.ruler
  local saved_showcmd = vim.o.showcmd
  vim.o.ruler = false
  vim.o.showcmd = false
  vim.cmd.redraw()

  local diff = #vim.fn.join(vim.tbl_values(info), ' ') - vim.o.columns + 2
  if diff > 0 then
    info.message = info.message:sub(1, #info.message - diff)
  end
  vim.api.nvim_echo({
    {info.version .. ' ', 'GitRevision'},
    {info.date .. ' ', 'GitDate'},
    {info.author .. ' ', 'GitAuthor'},
    {info.message},
  }, false, {})

  vim.o.ruler = saved_ruler
  vim.o.showcmd = saved_showcmd
end

local annotate_augroup = vim.api.nvim_create_augroup('git_annotate', {})
local function annotate(opts)
  local bufname = vim.fn.bufname()
  if bufname == log_name or bufname == '' then
    return
  end

  local bufnr = vim.fn.bufnr()
  local sign_group = 'git_annotate'

  if vim.b.git_annotations then
    vim.api.nvim_clear_autocmds({ buffer = bufnr, group = annotate_augroup })
    vim.fn.sign_unplace('git_annotate')
    vim.b.git_annotations = nil
    vim.cmd.echo() -- clear any existing annotation info
    if opts.range == 0 then -- don't return if a range is selected
      return
    end
  end

  local first, last
  if opts.range ~= 0 then
    first = opts.line1
    last = opts.line2
  else
    local wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1]
    first = wininfo['topline']
    last = wininfo['botline']
  end

  local root, path, revision = file(opts.path)
  if not path then
    return
  end

  -- only use an explicitly supplied revision or if viewing a show() buffer,
  -- then use the revision that is being shown
  local annotate_revision = opts.revision or (
    vim.b.git_info and vim.b.git_info.revision
  )
  local result = M.git(
    'annotate "' .. path .. '"' ..
    (annotate_revision and (' ' .. annotate_revision) or '') ..
    ' -L ' .. first .. ',' .. last
  )
  if not result then
    return
  end

  local annotations = vim.fn.split(result, '\n')
  annotations = vim.tbl_map(
    function(t)
      local rev, author, timestamp, lnum = t:match(
        '^(%w+)\t%(%s*([%w%s]+)\t([-+0-9%s:]+)\t(%d+)%).*'
      )
      local mapped = {
        lnum = tonumber(lnum),
        revision = rev,
        author = author,
        timestamp = timestamp,
      }
      if rev:match('^0+$') then
        mapped.author = 'uncomitted'
        mapped.uncommitted = true
      end
      return mapped
    end,
    annotations
  )

  if root and not me[root] then
    me[root] = M.git('config user.name')
  end

  local existing_signs = {}
  for _, signs in ipairs(vim.fn.sign_getplaced(bufnr)) do
    for _, sign in ipairs(signs.signs) do
      if not sign.name:match('^git_annotate_') then
        existing_signs[sign.lnum] = sign
      end
    end
  end

  local defined_signs = vim.tbl_map(
    function(s) return s.name end,
    vim.fn.sign_getdefined()
  )
  local previous
  for _, annotation in ipairs(annotations) do
    if not existing_signs[annotation.lnum] then
      local sign_name, sign_text
      if annotation.uncommitted then
        sign_name = 'git_annotate_uncommitted'
        sign_text = ' +'
      else
        local user = annotation.author
        local name_parts = vim.fn.split(user)
        -- if the user name appears to be in the form of First Last, then try
        -- using using the first letter of each as initials
        if #name_parts > 1 and
           name_parts[1]:match('^%w') and
           name_parts[2]:match('^%w')
        then
          sign_text = name_parts[1]:sub(1, 1) .. name_parts[2]:sub(1, 1)
        else
          sign_text = user:sub(1, 2)
        end

        if user == me[root] then
          sign_name = 'git_annotate_me'
        else
          sign_name = 'git_annotate_' .. user:sub(1, 6):gsub('%s+', '_')
        end
        if previous and annotation.revision == previous.revision then
          sign_name = sign_name .. '_cont'
          sign_text = ' ▕'
        end
      end

      if not vim.list_contains(defined_signs, sign_name) then
        local hl = 'GitAnnotate'
        if sign_name:match('^git_annotate_me') then
          hl = 'GitAnnotateMe'
        elseif sign_name == 'git_annotate_uncommitted' then
          hl = 'GitAnnotateUncommitted'
        end
        vim.fn.sign_define(sign_name, { text = sign_text, texthl = hl })
        defined_signs[#defined_signs + 1] = sign_name
      end
      vim.fn.sign_place(0, sign_group, sign_name, bufnr, {
        lnum = annotation.lnum,
        priority = 1, -- low priority so we don't shadow more important signs
      })
    end
    previous = annotation
  end

  vim.b.git_annotations = annotations
  set_info(root, path, revision)

  annotate_info()
  vim.api.nvim_clear_autocmds({ buffer = bufnr, group = annotate_augroup })
  vim.api.nvim_create_autocmd('CursorMoved', {
    buffer = bufnr,
    group = annotate_augroup,
    callback = annotate_info,
  })
  if vim.bo.buftype == '' then
    vim.api.nvim_create_autocmd('BufWritePost', {
      buffer = bufnr,
      group = annotate_augroup,
      callback = function()
        annotate() -- clear existing
        annotate() -- apply updated
      end,
    })
  end
end

M.show = function(opts)
  opts.revision = opts.revision or (opts.fargs and opts.fargs[1]) or 'HEAD'

  local root, path, revision = file(opts.path)
  if not path or not revision then
    error('Unable to determine file info.')
    return
  end

  local target_revision
  if opts.revision == 'prev' then
    target_revision = get_previous_revision(path, revision)
  else
    target_revision = get_revision(path, opts.revision)
  end

  if not target_revision then
    return
  end

  local result = M.git('show "' .. target_revision .. ':' .. path .. '"')
  if not result then
    return
  end

  local file_revision = target_revision
  if opts.revision and target_revision ~= opts.revision then
    file_revision = opts.revision .. '_' .. target_revision
  end

  local git_file = vim.fn.join({
    'git',
    file_revision,
    vim.fn.fnamemodify(path, ':t'),
  }, '_')
  window(git_file, opts.open or 'new', vim.fn.split(result, '\n'), {
    diff_sync = opts.diff_sync or not opts.path,
  })
  set_info(root, path, target_revision)
  return true
end

local diff_augroup = vim.api.nvim_create_augroup('git_diff', {})
local diff = function(opts)
  if vim.fn.bufname() == log_name then
    return
  end

  opts.revision = opts.revision or (opts.fargs and opts.fargs[1]) or 'HEAD'

  local _, path, revision = file()
  local target_revision
  if opts.revision == 'prev' then
    target_revision = get_previous_revision(path, revision)
  else
    target_revision = get_revision(path, opts.revision)
  end

  if not target_revision then
    return
  end

  local filename = vim.fn.expand('%:p')
  local bufnr = vim.fn.bufnr('%')

  local shown = M.show({
    path = path,
    revision = target_revision,
    open = 'below vertical new',
  })
  if shown then
    local diffbufnr = vim.fn.bufnr()
    vim.b.git_filename = filename
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

local log_line = function(details)
  return vim.fn.printf(
    '+ %s%s %s (%s)%s %s',
    details.mark,
    details.revision, ---@diagnostic disable-line: redundant-parameter
    details.author,   ---@diagnostic disable-line: redundant-parameter
    details.age,      ---@diagnostic disable-line: redundant-parameter
    details.refs,     ---@diagnostic disable-line: redundant-parameter
    details.comment   ---@diagnostic disable-line: redundant-parameter
  )
end

local log_revision = function()
  local lnum = vim.fn.search('^[+-] \\([<>-] \\)\\?\\w\\+', 'bcnW')
  local line = vim.fn.getline(lnum)
  return vim.fn.substitute(line, '[+-] \\([<>-] \\)\\?\\(\\w\\+\\) .*', '\\2', '')
end

local log_detail = function()
  local lnum = vim.fn.line('.')
  local line = vim.fn.getline(lnum)
  local revision = log_revision()

  local result = M.git(
    'log -1 --pretty=tformat:"%h|%an|%ar|%ai|%d|%s|%s%n%n%b|" ' .. revision
  )
  if not result then
    return
  end

  local mark = line:match('^[+-] ([<>-] )') or ''
  local values = vim.fn.split(result, '|')
  local details = {
    mark = mark,
    revision = values[1],
    author = values[2],
    age = values[3],
    date = values[4],
    refs = values[5],
    comment = values[6],
    description = values[7],
  }

  local settings = repo_settings()
  local ticket_id_pattern
  if settings.patterns then
    ticket_id_pattern = '\\(' ..
      vim.fn.join(vim.tbl_keys(settings.patterns), '\\|') ..
    '\\)\\>'
  end

  vim.bo.modifiable = true
  if line:match('^+') then
    local open = vim.fn.substitute(
      line, '+ \\(.\\{-})\\).*', '- \\1 ' .. details.date, ''
    )
    vim.fn.setline(lnum, open)

    local lines = {}
    if vim.b.git_info.path then
      if lnum == vim.fn.line('$') then
        lines[1] = "\t|view| |diff working copy|"
      else
        lines[1] = "\t|view| |diff working copy| |diff previous|"
      end
    end

    local desc = vim.fn.substitute(details.description, '\\_s*$', '', '')
    if ticket_id_pattern then
      desc = vim.fn.substitute(
        desc, '\\(' .. ticket_id_pattern .. '\\)', '|\\1|', 'g'
      )
    end
    local desc_lines = vim.tbl_map(
      function(l) return (l ~= '' and '\t' or '') .. l end,
      vim.fn.split(desc, '\n')
    )
    vim.list_extend(lines, desc_lines)
    lines[#lines + 1] = ''
    lines[#lines + 1] = '\t+ files |view patch|'
    vim.fn.append(lnum, lines)
    vim.cmd.retab()
  else
    local pos = vim.fn.getpos('.')
    vim.fn.setline(lnum, log_line(details))
    -- look for the next log entry, or if diffs are rendered, then up to that.
    local end_ = vim.fn.search('^[+-]\\s', 'nW') - 1
    if end_ == -1 then
      end_ = vim.fn.line('$')
    end
    vim.cmd(lnum + 1 .. ',' .. end_ .. 'delete _')
    vim.fn.setpos('.', pos)
  end
  vim.bo.modifiable = false
end

local log_files = function()
  local lnum = vim.fn.line('.')
  local line = vim.fn.getline(lnum)
  local revision = log_revision()

  vim.bo.modifiable = true
  if line:match('^%s+%+') then
    local results = M.git(
      'log -1 --name-status --pretty=tformat:"" ' .. revision
    )
    if not results then
      return
    end

    local root = vim.b.git_info.root
    local open = vim.fn.substitute(line, '+', '-', '')
    vim.fn.setline(lnum, open)

    local lines = {}
    for _, result in ipairs(vim.fn.split(results, '\n')) do
      local entry, entry_info
      local values = vim.fn.split(result, '\t')
      if result:match('^R') then
        entry_info = {
          status = values[1]:sub(1, 1),
          old = values[2],
          new = values[3],
        }
      else
        entry_info = {status = values[1]:sub(1, 1), file = values[2] }
      end

      if entry_info.status == 'R' then
        entry = entry_info.new
        if vim.fn.filereadable(root .. entry_info.new) ~= 0 then
          entry = '|' .. entry_info.new .. '|'
        end
        entry = entry_info.old .. ' -> ' .. entry
      else
        entry = entry_info.file
        if vim.fn.filereadable(root .. entry_info.file) ~= 0 then
          entry = '|' .. entry_info.file .. '|'
        end
      end
      lines[#lines + 1] = '\t\t|' .. entry_info.status .. '| ' .. entry
    end
    vim.fn.append(lnum, lines)
    vim.cmd.retab()
  else
    local pos = vim.fn.getpos('.')
    local close = vim.fn.substitute(line, '-', '+', '')
    vim.fn.setline(lnum, close)
    local start = lnum + 1
    local end_ = vim.fn.search('^[+-]\\s', 'cnW') - 1
    if end_ ~= lnum then
      if end_ == -1 then
        end_ = vim.fn.line('$')
      end
      if end_ < start then
        end_ = start
      end
      vim.cmd(start .. ',' .. end_ .. 'delete _')
      vim.fn.setpos('.', pos)
    end
  end
  vim.bo.modifiable = false
end

local log_open = function()
  local open = 'above new'
  if vim.b.git_filename then
    local winnr = vim.fn.bufwinnr(vim.b.git_filename)
    if winnr ~= -1 then
      vim.cmd(winnr .. 'winc w')
    end
  end
  return open
end

local log_patch = function()
  local revision = log_revision()
  local result = M.git('log -1 -p ' .. revision)
  if not result then
    return
  end
  window('git_' .. revision .. '.patch', 'modal', vim.fn.split(result, '\n'))
end

local log_diff = function(path1, path2)
  local open = log_open()
  M.show({
    path = path1.path,
    revision = path1.revision,
    open = open,
  })
  vim.cmd.diffthis()
  local buf1 = vim.fn.bufnr('%')

  M.show({
    path = path2.path,
    revision = path2.revision,
    open = 'below vertical split',
  })
  vim.cmd.diffthis()
  local buf2 = vim.fn.bufnr('%')

  vim.cmd(vim.fn.bufwinnr(buf1) .. 'winc w')

  vim.api.nvim_create_autocmd('BufWinLeave', {
    buffer = buf1,
    group = diff_augroup,
    callback = function()
      vim.cmd('silent! bdelete ' .. buf2)
    end,
  })
  vim.api.nvim_create_autocmd('BufWinLeave', {
    buffer = buf2,
    group = diff_augroup,
    callback = function()
      vim.cmd('silent! bdelete ' .. buf1)
    end,
  })
end

local log_action = function()
  local line = vim.fn.getline('.')
  local link = vim.fn.substitute(
    line, '.*|\\(.\\{-}\\%.c.\\{-}\\)|.*', '\\1', ''
  )

  if link == line and line:match('^%s+[+-] files |view patch|$') then
    log_files()
    return
  end

  if line:match('^[+-] [<>-]?%s*%w+') then
    log_detail()
    return
  end

  if link == line then
    return
  end

  local root = vim.b.git_info.root
  local settings = repo_settings()
  local ticket_id_patterns = settings.patterns
  local ticket_id_pattern
  if ticket_id_patterns then
    ticket_id_pattern = '\\(' ..
      vim.fn.join(vim.tbl_keys(ticket_id_patterns), '\\|') ..
    '\\)\\>'
  end

  -- link to commit patch
  if link == 'view patch' then
    log_patch()

  -- link to view / annotate a file
  elseif link == 'view' then
    local revision = log_revision()
    local path = vim.b.git_info.path
    local open = log_open()
    M.show({
      path = path,
      revision = revision,
      open = open,
      diff_sync = true,
    })

  -- link to diff version against current/previous
  elseif link:match('^diff ') then
    local revision = log_revision()
    local path = vim.b.git_info.path

    if link:match('previous') then
      local previous = get_previous_revision(path, revision)
      if previous then
        log_diff(
          { path = path, revision = revision },
          { path = path, revision = previous }
        )
      end
    else
      local filename = vim.b.git_filename
      log_open()
      local shown = M.show({
        path = path,
        revision = revision,
        open = 'below vertical new',
      })
      if shown then
        local winnr = vim.fn.bufwinnr(filename)
        if winnr ~= -1 then
          vim.cmd.diffthis()
          vim.cmd(winnr .. 'winc w')
          vim.cmd.diffthis()
        end
      end
    end

  -- link to bug / feature report
  elseif ticket_id_pattern and
         vim.fn.match(link, '^' .. ticket_id_pattern .. '$') ~= -1
  then
    -- we matched our combined pattern, now loop over our list of patterns to
    -- find the exact pattern matched and the url it maps to
    local ticket_pattern, ticket_url
    for pattern, url in pairs(ticket_id_patterns) do
      if vim.fn.match(link, '^' .. pattern .. '$') ~= -1 then
        ticket_pattern = pattern
        ticket_url = url
        break
      end
    end

    if ticket_url then
      local id = vim.fn.substitute(link, ticket_pattern, '\\1', '')
      ticket_url = vim.fn.substitute(ticket_url, '<id>', id, 'g')
      local result = vim.fn.system('xdg-open "' .. ticket_url .. '"')
      if vim.v.shell_error ~= 0 then
        error('Error running xdg-open:' .. '\n' .. result)
      end
    end

  elseif link == 'A' or link == 'M' or link == 'R' or link == 'D' then
    local revision = log_revision()
    -- pattern to match the file name after the link, which may itself be a
    -- link to the current version of the file
    local regex = '.*|' .. link .. '|\\s\\+|\\?\\(.\\{-}\\)\\(|\\|$\\)'

    -- added file
    if link == 'A' then
      local path = vim.fn.substitute(line, regex, '\\1', '')
      M.show({
        path = path,
        revision = revision,
        open = 'modal',
      })

    -- deleted file
    elseif link == 'D' then
      local path = vim.fn.substitute(line, regex, '\\1', '')
      local previous = get_previous_revision(path, revision)
      M.show({
        path = path,
        revision = previous,
        open = 'modal',
      })
    else
      local path, old, previous
      -- modified file
      if link == 'M' then
        path = vim.fn.substitute(line, regex, '\\1', '')
        old = path
        previous = get_previous_revision(path, revision)

      -- renamed file
      else
        local old_regex = vim.fn.substitute(regex, '\\$', '\\\\>', '') .. '\\s->.*'
        old = vim.fn.substitute(line, old_regex, '\\1', '')
        previous = get_previous_revision(old, revision)

        local new_regex = vim.fn.substitute(regex, '|R|', '|R|.*->', '')
        path = vim.fn.substitute(line, new_regex, '\\1', '')
      end

      log_diff(
        { path = path, revision = revision },
        { path = old, revision = previous }
      )
    end

  -- file reference
  elseif vim.fn.filereadable(root .. link) ~= 0 then
    local filename = root .. link

    -- make relative if possible
    filename = vim.fn.fnamemodify(filename, ':.')

    local winnr = vim.fn.bufwinnr(filename)
    if winnr == -1 then
      vim.cmd('above new ' .. filename)
    else
      vim.cmd(winnr .. 'winc w')
    end
  end
end

local log_augroup = vim.api.nvim_create_augroup('git_log', {})
local log = function(opts)
  if opts.bang and opts.range ~= 0 then
    error('Git! log cannot be used with a range.')
    return
  end

  local root, path
  local filename

  -- check if command is using % expansion
  local expanded = opts.fargs_orig and vim.list_contains(opts.fargs_orig, '%')

  if not opts.bang or expanded then
    -- logging from the log window
    if vim.fn.bufname() == log_name and vim.b.git_filename then
      filename = vim.b.git_filename

    -- logging from a show() buffer (eg. :Git show prev, then annotate)
    elseif vim.b.git_info and vim.b.git_info.path then
      filename = vim.b.git_info.path

    else
      filename = vim.fn.expand('%:p')
      if filename == '' or
         vim.fn.bufname() == log_name or
         vim.fn.bufname() == status_name
      then
        filename = nil
      end
    end
  end

  if filename then
    root, path, _ = file(filename)
  else
    root = repo()
  end

  -- TODO: add completion of branch names
  local expansions = {
    ['diff:([-%w]+)'] = {'diff between <match>', '<branch>...<match>'},
    ['in:([-%w]+)'] = {'incoming from <match>', '--right-only <branch>...<match>'},
    ['out:([-%w]+)'] = {'outgoing to <match>', '--left-only <branch>...<match>'},
  }
  for i, arg in ipairs(opts.fargs or {}) do
    for pattern, expansion in pairs(expansions) do
      local match = arg:match(pattern)
      if match then
        local branch = M.git('rev-parse --abbrev-ref HEAD')
        if branch then
          opts.fargs[i] = expansion[2]
            :gsub('<branch>', branch)
            :gsub('<match>', match)
          opts.args = vim.fn.join(opts.fargs, ' ')
          opts.title = 'filter:       ' .. expansion[1]
            :gsub('<branch>', branch)
            :gsub('<match>', match)
        end
        break
      end
    end
  end

  local log_cmd = 'log --pretty=tformat:"%m|%h|%an|%ar|%d|%s"'
  if opts.args and opts.args ~= '' then
    if opts.args:match('--graph') then
      term('git log ' .. opts.args, { cwd = repo() })
      return
    end
    log_cmd = log_cmd .. ' ' .. opts.args

    -- if command is using % expansion then prevent adding the path to the args
    -- a second time below
    if filename and expanded then
      opts.title = ('filename:     ' .. path)
      path = nil
    end
  end

  if not root then
    return
  end

  if path then
    if opts.range ~= 0 then
      log_cmd = log_cmd .. ' -L' .. opts.line1 .. ',' .. opts.line2 .. ':'
    else
      log_cmd = log_cmd .. ' --follow '
    end
    log_cmd = log_cmd .. path
  end

  local result = M.git(log_cmd, opts)
  if not result then
    return
  end

  local lines = {
    'repository:   ' .. vim.fn.fnamemodify(root, ':h:t'),
    'branch:       ' .. M.git('rev-parse --abbrev-ref HEAD'),
  }
  if opts.title or path then
    lines[#lines + 1] = opts.title or ('filename:     ' .. path)
  end
  lines[#lines + 1] = ''

  local cursor = #lines + 1
  local skipped = false
  for _, line in ipairs(vim.fn.split(result, '\n')) do
    local values = vim.fn.split(line, '|')
    if #values == 6 then
      lines[#lines + 1] = log_line({
        mark = (opts.title and opts.title:match('^filter:%s+diff')) and
          (values[1] .. ' ') or
          '',
        revision = values[2],
        author = values[3],
        age = values[4],
        refs = values[5],
        comment = values[6],
      })
      skipped = false

    -- when logging a range, skip the blank line before the diff output
    elseif line == '' and not skipped then
      skipped = true

    else
      -- skip these lines since thye are redundant
      if not line:match('^diff %-%-git') and
         not line:match('^%-%-%- a/') and
         not line:match('^+++ b/')
      then
        lines[#lines + 1] = '# ' .. line
      end
    end
  end

  -- if the cursor is on an annotation line, then jump to that log entry
  local annotation
  if path and vim.b.git_annotations then
    local first = vim.b.git_annotations[1].lnum
    local last = vim.b.git_annotations[#vim.b.git_annotations].lnum
    local lnum = vim.fn.line('.')
    if first <= lnum and lnum <= last then
      annotation = vim.b.git_annotations[lnum - first + 1]
    end
  end

  local height = 15
  window(log_name, 'botright ' .. height .. 'new', lines)
  vim.w.height = height -- for other plugins that may need to restore the height
  vim.wo.statusline = '%<%f %=%-10.(%l,%c%V%) %P'
  vim.wo.wrap = false
  vim.wo.winfixheight = true
  vim.fn.cursor(cursor, 1)
  vim.cmd.resize(height)
  vim.cmd.doautocmd('WinNew')
  vim.cmd.doautocmd('WinEnter')

  vim.bo.ft = 'git_log'
  vim.cmd('syntax match GitRevision /\\(^[+-] \\([<>-] \\)\\?\\)\\@<=\\w\\+/')
  vim.cmd('syntax match GitAuthor /\\(^[+-] \\([<>-] \\)\\?\\w\\+ \\)\\@<=.\\{-}\\( (\\)\\@=/')
  vim.cmd('syntax match GitDate /\\(^[+-] \\([<>-] \\)\\?\\w\\+ \\w.\\{-}\\)\\@<=(\\d.\\{-})/')
  vim.cmd('syntax match GitRefs /\\(^[+-] \\([<>-] \\)\\?\\w\\+ \\w.\\{-} (\\d.\\{-}) \\)\\@<=(.\\{-})/')
  vim.cmd('syntax match GitMessage /\\(^[+-] \\([<>-] \\)\\?\\w\\+ \\w.\\{-} (\\d.\\{-})\\( (.\\{-})\\)\\?\\)\\@<=.*/ contains=GitRefs')
  vim.cmd('syntax match GitLink /|\\S.\\{-}|/')
  vim.cmd('syntax match GitFiles /\\(^\\s\\+[+-] \\)\\@<=files\\>/')
  vim.cmd('syntax match GitLogHeader /^\\%<4l.\\{-}: .*/ contains=GitLogHeaderName,GitLogHeaderFile')
  vim.cmd('syntax match GitLogHeaderName /^\\%<4l.\\{-}:/')
  vim.cmd('syntax match GitLogHeaderFile /\\(\\%<4lfilename:\\s\\+\\)\\@<=.*/')
  vim.cmd('syntax match GitLogDiff /^# .*/ contains=GitLogDiffAdd,GitLogDiffDelete')
  vim.cmd('syntax match GitLogDiffAdd /\\(^# \\)\\@<=+.*/')
  vim.cmd('syntax match GitLogDiffDelete /\\(^# \\)\\@<=-.*/')
  vim.cmd('syntax match GitLogMarkerIn /\\(^[+-] \\)\\@<=>/')
  vim.cmd('syntax match GitLogMarkerOut /\\(^[+-] \\)\\@<=</')

  set_info(root, path, nil)

  if annotation and not annotation.uncommitted then
    local revision = annotation.revision
    -- the annotate hash may be longer than the log hash, so perform a little
    -- extra work to ensure the revision is as long or shorter than the log hash
    local sample_line = vim.fn.search('^[+-] \\w\\+', 'n')
    if sample_line ~= -1 then
      local sample_hash = vim.fn.getline(sample_line):match('^[+-] (%w+)')
      revision = revision:sub(1, #sample_hash)
    end
    vim.fn.search('^[+-] ' .. revision)
    vim.cmd('normal! z') -- move line to top of the log window
  end

  local bufnr = vim.fn.bufnr()
  vim.keymap.set('n', '<cr>', log_action, { buffer = bufnr })
  vim.api.nvim_clear_autocmds({ group = log_augroup })
  vim.b.git_filename = filename
  vim.api.nvim_create_autocmd('BufWinLeave', {
    buffer = bufnr,
    group = log_augroup,
    callback = function()
      local winnr = vim.fn.bufwinnr(vim.b.git_filename or status_name)
      if winnr ~= -1 then
        vim.schedule(function()
          vim.cmd(winnr .. 'winc w')
          vim.cmd.doautocmd('BufEnter')
        end)
      end
    end,
  })
end

local log_grep = function(type, opts)
  local log_args
  if not opts.args or opts.args:match('^%s*$') then
    error('Please supply a pattern to search for.', 'WarningMsg')
    return
  end

  local args = vim.fn.escape(opts.args, '"')
  if type == 'commits' then
    log_args = '-E "--grep=' .. args .. '"'
  elseif type == 'files' then
    log_args = '--pickaxe-regex "-S' .. args .. '"'
  end

  if not log_args then
    return
  end

  log({
    args = log_args,
    title = opts.title .. args,
    exec = type == 'files',
  })
end

local grep_commits = function(opts)
  opts.title = 'grep commits: '
  log_grep('commits', opts)
end

local grep_files = function(opts)
  opts.title = 'grep files:   '
  log_grep('files', opts)
end

local status_term_exit = function(term_bufnr, exit_code)
  local opts = { focus = true }
  -- only close the term window if the command completed successfully,
  -- otherwise allow the user to see the error output
  if exit_code == 0 then
    vim.cmd.bdelete(term_bufnr)
  else
    -- on error, don't steal focus from the term window
    opts.focus = false
  end
  if vim.fn.bufwinnr(status_name) ~= -1 then
    status(opts)
  end
end

local status_branch_switch = function(selection, prompt_text)
  if selection then
    local name = selection.value
    if M.git('switch ' .. name) then
      notify('Current branch: ' .. name)
      pcall(vim.cmd.checktime) -- update existing buffers if necessary
      status()
    end
  else
    local name = prompt_text
    local branch = M.git('rev-parse --abbrev-ref HEAD')
    local msg = 'Create new branch ' .. name .. ' from ' .. branch .. '?'
    local result = confirm(msg, '&yes\n&no')
    if result == 1 then
      if M.git('switch -c ' .. name) then
        notify('Created new branch: ' .. name)
        status()
      end
    end
  end
end

local status_branch_merge = function(selection)
  if selection then
    local name = selection.value
    local branch = M.git('rev-parse --abbrev-ref HEAD')
    local msg = 'Merge branch ' .. name .. ' into ' .. branch .. '?'
    local result = confirm(msg, '&yes\n&no')
    if result == 1 then
      local cmd = config.branch_merge or 'merge'
      if not cmd:match('^[-%w]+$') then
        error('branch_merge must be a git command or alias')
        return
      end
      term('git ' .. cmd .. ' ' .. name, {
        cwd = repo(),
        on_exit = function()
          pcall(vim.cmd.checktime) -- update existing buffers if necessary
          status_term_exit()
        end,
      })
    end
  end
end

local status_branch_rebase = function(selection)
  if selection then
    local name = selection.value
    local branch = M.git('rev-parse --abbrev-ref HEAD')
    local msg = 'Rebase branch ' .. branch .. ' against ' .. name .. '?'
    local result = confirm(msg, '&yes\n&no')
    if result == 1 then
      term('git rebase ' .. name, {
        cwd = repo(),
        on_exit = function()
          pcall(vim.cmd.checktime) -- update existing buffers if necessary
          status_term_exit()
        end,
      })
    end
  end
end

local status_branch_delete = function(selection)
  if selection then
    local branch = M.git('rev-parse --abbrev-ref HEAD')
    local name = selection.value
    if name == branch then
      vim.schedule(function()
        error('Current branch cannot be deleted: ' .. name)
      end)
      return
    end
    local msg = 'Delete branch? ' .. name
    local result = confirm(msg, '&yes\n&force\n&no')
    vim.cmd.redraw()
    if not result or result == 3 then
      return
    end

    local remote = M.git(
      'config get branch.' .. name .. '.remote',
      { quiet = true }
    )
    local flag = result == 2 and ' -D ' or ' -d '
    if M.git('branch' .. flag .. name) then
      notify('Deleted local branch: ' .. name)
      if remote then
        msg = 'Delete remote? ' .. remote .. '/' .. name
        result = confirm(msg, '&yes\n&no')
        vim.cmd.redraw()
        if result == 1 then
          term('git push ' .. remote .. ' -d ' .. name, {
            cwd = repo(),
            echo = 'deleting ' .. remote .. '/' .. name .. '...',
          })
        end
      end
    end
  end
end

local status_branch_cmd = function(cmd)
  return function()
    local loaded, builtin = pcall(require, 'telescope.builtin')
    if loaded and builtin then
      local actions = require('telescope.actions')
      local action_state = require('telescope.actions.state')
      local cmd_func
      if cmd == 'switch' then
        cmd_func = status_branch_switch
      elseif cmd == 'merge' then
        cmd_func = status_branch_merge
      elseif cmd == 'rebase' then
        cmd_func = status_branch_rebase
      elseif cmd == 'delete' then
        cmd_func = status_branch_delete
      else
        return
      end

      builtin.git_branches({
        previewer = false,
        prompt_title = 'Git branch: ' .. cmd,
        show_remote_tracking_branches = false,
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            local picker = action_state.get_current_picker(prompt_bufnr)
            local prompt_text = picker:_get_prompt()
            actions.close(prompt_bufnr)
            cmd_func(selection, prompt_text)
          end)
          -- effectively remove the default mappings for this instance
          local noop = function() end
          map({ 'i', 'n' }, '<c-t>', noop)
          map({ 'i', 'n' }, '<c-r>', noop)
          map({ 'i', 'n' }, '<c-a>', noop)
          map({ 'i', 'n' }, '<c-s>', noop)
          map({ 'i', 'n' }, '<c-d>', noop)
          map({ 'i', 'n' }, '<c-y>', noop)
          return true
        end,
      })
    end
  end
end

local status_pending_line = 1
local status_head_line = 2
local status_repo_actions_line = 4
local status_action = function()
  if vim.fn.mode() == 'V' then
    local pos1 = vim.fn.getpos('v')
    local pos2 = vim.fn.getpos('.')
    local lines = vim.tbl_filter(function(l)
      -- ignore comment lines and untracked files
      return not (l:sub(1, 1) == '#' or l:sub(1, 1) == '?')
    end, vim.fn.getregion(pos1, pos2, { type = 'V' }))
    if #lines then
      local paths = vim.fn.join(
        vim.tbl_map(function(l) return l:sub(4) end, lines),
        ' '
      )
      local result = M.git('diff HEAD ' .. paths)
      if result then
        window('git_HEAD.patch', 'modal', vim.fn.split(result, '\n'))
      end
    end

    -- clear --VISUAL *-- mode status
    local esc = vim.api.nvim_replace_termcodes('<esc>', true, false, true)
    vim.fn.feedkeys(esc, 'nt')
    vim.cmd('redraw!')
    return
  end

  local lnum = vim.fn.line('.')
  local line = vim.fn.getline(lnum)

  if lnum == status_pending_line then
    local branch_match = vim.fn.substitute(
      line, '^## \\([^[:space:]]\\{-}\\%.c\\)', '\\1', ''
    )
    if branch_match ~= line then
      status_branch_cmd('switch')()
      return
    end

    local pending_match = vim.fn.substitute(
      line, '.*\\(\\[.\\{-}\\%.c.\\{-}\\]\\)', '\\1', ''
    )
    if pending_match ~= line then
      local pending = vim.fn.expand('<cword>')
      if pending == 'ahead' then
        log({ title = 'commits:      outbound', args = '@{upstream}..'})
      elseif pending == 'behind' then
        log({ title = 'commits:      inbound', args = '..@{upstream}'})
      end
      return
    end
  end

  if lnum == status_repo_actions_line then
    local word = vim.fn.expand('<cword>')
    if word == 'stashes' then
      vim.bo.modifiable = true
      if vim.fn.getline(lnum + 1):match('^## %-') then
        local pos = vim.fn.getpos('.')
        while vim.fn.getline(lnum + 1):match('^## %-') do
          vim.cmd(lnum + 1 .. 'delete _')
        end
        vim.fn.setpos('.', pos)
        vim.b.git_stashes = false
      else
        local stashes = M.git('stash list')
        if stashes then
          vim.fn.append(lnum, vim.tbl_map(function(s)
            return '## - ' .. s
          end, vim.fn.split(stashes, '\n')))
          vim.b.git_stashes = true
        else
          status() -- if there aren't any commits, then we might be out of date
        end
      end
      vim.bo.modifiable = false
    end
  end

  if lnum == status_head_line then
    if vim.fn.col('.') > 3 then
      log({ title = 'commits:      HEAD', args = '-1'})
    end
    return
  end

  local stash = line:match('^## %- (stash@{%d+}):.*')
  if stash then
    local result = M.git('stash show -p ' .. stash)
    if result then
      window('git_' .. stash .. '.patch', 'modal', vim.fn.split(result, '\n'))
    end
  end

  -- ignore comment lines
  if line:sub(1, 1) == '#' then
    return
  end

  local col = vim.fn.col('.')
  local status_bufnr = vim.fn.bufnr()

  local path = line:sub(4)
  -- handle renames
  if path:match('%->') then
    path = path:match('%->%s+(.*)')
  end

  -- act on the status
  if col <= 2 then
    local status = line:sub(col, col)
    if status == 'A' then
      local result = M.git('show ":' .. path .. '"')
      if not result then
        return
      end
      window(path, 'modal', vim.fn.split(result, '\n'))
    elseif status == 'D' then
      local revision = M.git(
        'rev-list --abbrev-commit -n 1 HEAD -- ' .. '"' .. path .. '"'
      )
      M.show({
        path = path,
        revision = revision,
        open = 'modal',
      })
    elseif status == 'M' then
      local staged = col == 1
      local diff_cmd = 'diff ' .. (staged and '--cached ' or '')
      local result = M.git(diff_cmd .. '"' .. path .. '"')
      if not result then
        return
      end
      window(path .. '.patch', 'modal', vim.fn.split(result, '\n'))
    end

  -- open the file if it hasn't been deleted
  elseif not line:gsub('^%s', ''):match('^D') then
    local winnr = vim.fn.bufwinnr(path)
    if winnr == -1 then
      vim.cmd('above new ' .. path)
    else
      vim.cmd(winnr .. 'winc w')
    end
  end

  local bufnr = vim.fn.bufnr()
  if bufnr ~= status_bufnr then
    vim.api.nvim_create_autocmd('WinClosed', {
      buffer = bufnr,
      callback = function()
        local winnr = vim.fn.bufwinnr(status_bufnr)
        if winnr ~= -1 then
          vim.cmd(winnr .. 'winc w')
        end
      end,
      once = true,
    })
  end
end

local status_cmd = function(cmd, opts)
  opts = opts or {}

  local lines
  if vim.fn.mode() == 'V' then
    local pos1 = vim.fn.getpos('v')
    local pos2 = vim.fn.getpos('.')
    lines = vim.fn.getregion(pos1, pos2, { type = 'V' })

    -- clear --VISUAL *-- mode status
    if not opts.term then
      local esc = vim.api.nvim_replace_termcodes('<esc>', true, false, true)
      vim.fn.feedkeys(esc, 'nt')
      vim.cmd('redraw!')
    end
  else
    lines = { vim.fn.getline('.') }
  end

  -- filter out lines we want to ignore
  lines = vim.tbl_filter(function(l)
    -- ignore comment lines
    if l:sub(1, 1) == '#' then
      return false
    end

    if opts.untracked == false and l:sub(1, 1) == '?' then
      return false
    end

    if opts.filter then
      return opts.filter(l)
    end

    return true
  end, lines)

  if #lines == 0 then
    return
  end

  if opts.confirm then
    local msg = opts.confirm(lines)
    if msg then
      local result = confirm(msg, '&yes\n&no')
      if result ~= 1 then
        return
      end
    end
  end

  local paths = vim.fn.join(
    vim.tbl_map(function(l)
      local path = l:sub(4)
      if path:match('%->') then
        path = path:match('%->%s+(.*)')
      end
      return path
    end, lines),
    ' '
  )
  if opts.term then
    term('git ' .. cmd .. ' ' .. paths, {
      cwd = repo(),
      on_exit = status_term_exit,
    })
  else
    M.git(cmd .. ' ' .. paths)
    status()
  end
end

local status_augroup = vim.api.nvim_create_augroup('git_status', {})
function status(opts) ---@diagnostic disable-line: lowercase-global
  local result = M.git('status -sb')
  if not result then
    return
  end

  local lines = vim.fn.split(result, '\n')
  local branch = M.git('rev-parse --abbrev-ref HEAD')
  local stashes = vim.fn.split(M.git('stash list') or '', '\n')
  local head = M.git('log -1 "--pretty=format:%h %an: %s"')
  local branch_actions = 'gi(t) branch + [s]witch [m]erge [r]ebase [d]elete'
  local repo_actions = '(f)etch'
  local file_actions = '(s)tage (i)nteractive (u)nstage (r)estore (d)elete'
  local is_ahead = result:match('%[ahead %d+')
  local is_behind = result:match('[%[%s]behind %d+')
  local is_gone = result:match('%[gone%]') -- remote is set but doesn't exist
  local can_amend = is_ahead or not is_protected(branch)
  local can_commit = false
  for _, line in ipairs(lines) do
    if line:match('^[ADMR]') then
      can_commit = true
      break
    end
  end

  if can_commit then
    repo_actions = repo_actions .. ' (c)ommit'
  end
  if can_amend then
    repo_actions = repo_actions .. ' (a)mend'
  end
  if is_ahead then
    if is_behind and not is_protected(branch) then
      repo_actions = repo_actions .. ' (P)ush force'
    else
      repo_actions = repo_actions .. ' (p)ush'
    end
  elseif is_behind then
    repo_actions = repo_actions .. ' (m)erge'
  elseif is_gone then
    repo_actions = repo_actions .. ' (p)ush'
  end
  if #stashes > 0 then
    repo_actions = repo_actions .. ' [stashes: ' .. #stashes .. ']'
  end
  lines = vim.list_extend({
    lines[1],
    '## HEAD: ' .. head,
    '## ' .. branch_actions,
    '## ' .. repo_actions,
    '## ' .. file_actions,
  }, lines, 2)

  -- attempt to retain the cursor position when refreshing
  local pos
  local winnr = vim.fn.bufwinnr(status_name)
  if winnr ~= -1 then
    vim.cmd(winnr .. 'winc w')
    pos = vim.fn.getpos('.')
  end

  local height = 15
  window(status_name, 'botright ' .. height .. 'new', lines, {
    created = function()
      local nav = function(dir)
        -- if we are on the pending commits line, then reset our position
        if vim.fn.line('.') == status_pending_line then
          vim.fn.cursor(0, 1)
        end
        vim.cmd('normal! ' .. dir)

        local lnum = vim.fn.line('.')
        local line = vim.fn.getline(lnum)
        local col = vim.fn.col('.')
        if col == 1 and line:sub(1, 1) == ' ' then
          vim.fn.cursor('.', 2) ---@diagnostic disable-line: param-type-mismatch
        elseif col == 2 and line:sub(2, 2) == ' ' then
          vim.fn.cursor('.', 1) ---@diagnostic disable-line: param-type-mismatch
        end
      end
      vim.keymap.set('n', 'j', function()
        nav('j')
      end, { buffer = true })
      vim.keymap.set('n', 'k', function()
        nav('k')
      end, { buffer = true })
    end,
  })

  set_info(repo())

  -- restore the state of our stashes
  if vim.b.git_stashes then
    if vim.fn.search('\\[stashes:') ~= 0 then
      vim.fn.cursor(0, vim.fn.col('.') + 1)
      status_action()
    end
  end

  if pos then
    vim.fn.setpos('.', pos)
  else
    -- place the cursor on the first status char we find
    if vim.fn.search('^[^#]') ~= 0 then
      vim.cmd.normal('jk')
    end
  end

  vim.w.height = height -- for other plugins that may need to restore the height
  vim.wo.statusline = '%<%f %=%-10.(%l,%c%V%) %P'
  vim.wo.wrap = false
  vim.wo.winfixheight = true
  vim.cmd.resize(height)

  vim.bo.ft = 'git_status'
  vim.cmd('syntax match GitStatusAdded /\\%1cA/')
  vim.cmd('syntax match GitStatusAhead /\\(\\%1l.*\\[\\)\\@<=ahead \\d\\+/')
  vim.cmd('syntax match GitStatusBehind /\\(\\%1l.*[\\[\\|,[:space:]]\\)\\@<=behind \\d\\+/')
  vim.cmd('syntax match GitStatusBranchLocal /\\(\\%1l## \\)\\@<=.\\{-}\\(\\.\\.\\.\\|$\\)/')
  vim.cmd('syntax match GitStatusBranchRemote /\\(\\%1l## .*\\.\\.\\.\\)\\@<=.\\{-}\\(\\s\\|$\\)/')
  vim.cmd('syntax match GitStatusComment /^#.*/ contains=' ..
    'GitAuthor,' ..
    'GitMessage,' ..
    'GitRevision,' ..
    'GitStatusAhead,' ..
    'GitStatusBehind,' ..
    'GitStatusBranchLocal,' ..
    'GitStatusBranchRemote,' ..
    'GitStatusStash'
  )
  vim.cmd('syntax match GitStatusDeleted /\\%2cD/')
  vim.cmd('syntax match GitStatusDeletedStaged /\\%1cD/')
  vim.cmd('syntax match GitStatusDeletedFile /\\(\\%1cD\\|\\%2cD\\)\\@<=.*/')
  vim.cmd('syntax match GitStatusModified /\\%2cM/')
  vim.cmd('syntax match GitStatusModifiedStaged /\\%1cM/')
  vim.cmd('syntax match GitStatusRenamedStaged /\\%1cR/')
  vim.cmd('syntax match GitStatusStash /\\(^## - \\)\\@<=stash@{.*/')
  vim.cmd('syntax match GitStatusUntracked /^?.*/')
  -- same highlight groups as log, but different patterns
  vim.cmd('syntax match GitRevision /\\(^## HEAD: \\)\\@<=\\w\\+/')
  vim.cmd('syntax match GitAuthor /\\(^## HEAD: \\w\\+ \\)\\@<=.\\{-}\\(:\\s\\)\\@=/')
  vim.cmd('syntax match GitMessage /\\(^## HEAD: \\w\\+ \\w.\\{-}:\\s\\)\\@<=.*/')

  local bufnr = vim.fn.bufnr()

  vim.keymap.set('n', 't', function()
    local actions = { 'switch', 'merge', 'rebase', 'delete' }
    local action = confirm(
      'Choose a branch action:',
      '&' .. vim.fn.join(actions, '\n&')
    )
    if action then
      vim.cmd.normal('t' .. actions[action]:sub(1, 1))
      vim.cmd.startinsert()
    end
  end, { buffer = bufnr })
  vim.keymap.set('n', 'ts', status_branch_cmd('switch'), { buffer = bufnr })
  vim.keymap.set('n', 'tm', status_branch_cmd('merge'),  { buffer = bufnr })
  vim.keymap.set('n', 'tr', status_branch_cmd('rebase'), { buffer = bufnr })
  vim.keymap.set('n', 'td', status_branch_cmd('delete'), { buffer = bufnr })

  vim.keymap.set({ 'n', 'x' }, '<cr>', status_action, { buffer = bufnr })
  vim.keymap.set({ 'n', 'x' }, 's', function()
    status_cmd('stage')
  end, { buffer = bufnr })
  vim.keymap.set({ 'n', 'x' }, 'i', function()
    status_cmd('stage -p', {
      term = true,
      filter = function(line)
        -- only allow entries with unstaged changes
        return line:match('^.M')
      end,
    })
  end, { buffer = bufnr })
  vim.keymap.set({ 'n', 'x' }, 'u', function()
    status_cmd('restore --staged', { untracked = false })
  end, { buffer = bufnr })
  vim.keymap.set('n', 'r', function()
    status_cmd('restore', {
      confirm = function(selection)
        local affected = vim.tbl_filter(function(l)
          return l:match('^%sM') and true or false
        end, selection)
        if #affected > 0 then
          return 'Are you sure you want to run: ' ..
            'git restore on ' .. #selection .. ' file(s)? ' ..
            '(unstaged changes will be lost)'
        end
      end,
      filter = function(line)
        -- only allow entries with unstaged changes
        return line:match('^.[MD]')
      end,
      untracked = false,
    })
    pcall(vim.cmd.checktime) -- update existing buffers if necessary
  end, { buffer = bufnr })
  vim.keymap.set({ 'n', 'x' }, 'd', function()
    status_cmd('clean -f', {
      confirm = function(selection)
        return 'Are you sure you want to run: ' ..
          'git clean -f on ' .. #selection .. ' file(s)? ' ..
          '(this cannot be undone)'
      end,
      filter = function(line)
        -- only allow untracked entries
        return line:sub(1, 1) == '?'
      end,
    })
  end, { buffer = bufnr })

  vim.keymap.set('n', 'f', function()
    term('git fetch', {
      cwd = repo(),
      echo = 'fetching...',
      on_exit = function()
        -- call instead of supplying as on_exit, so that the term stays open
        -- for review
        status_term_exit()
      end
    })
  end, { buffer = bufnr })

  vim.keymap.set('n', 'c', function()
    if can_commit then
      term('git commit -e', { cwd = repo(), on_exit = status_term_exit })
    end
  end, { buffer = bufnr })

  vim.keymap.set('n', 'a', function()
    if can_amend then
      term('git commit --amend', { cwd = repo(), on_exit = status_term_exit })
    end
  end, { buffer = bufnr })

  vim.keymap.set('n', 'm', function()
    if is_behind then
      term(is_ahead and 'git rebase' or 'git merge', {
        cwd = repo(),
        echo = is_ahead and 'rebasing...' or 'merging...',
        on_exit = function()
          pcall(vim.cmd.checktime) -- update existing buffers if necessary
          status_term_exit()
        end
      })
    end
  end, { buffer = bufnr })

  vim.keymap.set('n', 'p', function()
    if is_ahead then
      term('git push', {
        cwd = repo(),
        echo = 'pushing...',
        on_exit = status_term_exit,
      })
    end
  end, { buffer = bufnr })

  vim.keymap.set('n', 'P', function()
    if is_ahead then
      term('git push -f', {
        cwd = repo(),
        echo = 'force pushing...',
        on_exit = status_term_exit,
      })
    end
  end, { buffer = bufnr })

  vim.api.nvim_clear_autocmds({ group = status_augroup })
  vim.api.nvim_create_autocmd('BufUnload', {
    buffer = bufnr,
    group = status_augroup,
    callback = function()
      vim.api.nvim_clear_autocmds({ group = status_augroup })
    end,
  })
  vim.api.nvim_create_autocmd('BufWritePost', {
    pattern = '*',
    group = status_augroup,
    callback = function()
      status({ focus = false })
    end,
  })

  opts = opts or {}
  local focus = opts.focus == nil and true or opts.focus
  if not focus then
    vim.cmd.winc('p')
  end
end

local commands = {
  annotate = annotate,
  diff = diff,
  log = log,
  show = M.show,
  status = status,
  ['grep-commits'] = grep_commits,
  ['grep-files'] = grep_files,
}

local complete_filepath = function(compl_opts)
  local arglead = compl_opts.arglead
  local root = repo()
  local results = vim.fn.glob(root .. arglead .. '*', nil, true)
  results = vim.tbl_map(function(r)
    local rel = r:sub(#root + 1)
    if vim.fn.isdirectory(r) == 1 then
      rel = rel .. '/'
    end
    return rel
  end, results)
  return compl_opts.match, results
end

local complete_branch = function(prefix)
  return function(compl_opts)
    local branches = M.git('branch -a --format="%(refname:short)"') or ''
    local results = vim.tbl_map(function(b)
      return prefix and (prefix .. b) or b
    end, vim.fn.split(branches, '\n'))
    local match = prefix and (prefix .. compl_opts.match) or compl_opts.match
    return match, results
  end
end

local complete = function(arglead, cmdl, pos)
  local pre = string.sub(cmdl, 1, pos)
  local results = {}
  local opts = { arglead = arglead, cmdl = cmdl, pos = pos}
  local completions = {
    -- complete command names
    ['^Git%s+([-%w]*)$'] = function(compl_opts)
      local cmds = {}
      local all = vim.fn.system(
        'git help -a | grep "^\\s\\+\\w" | perl -pe "s|^\\s+(\\S+)\\s.*|\\1|"'
      )
      if vim.v.shell_error == 0 then
        cmds = vim.fn.split(all, '\n')
      end
      for cmd, _ in pairs(commands) do
        if not vim.list_contains(cmds, cmd) then
          cmds[#cmds + 1] = cmd
        end
      end
      return compl_opts.match, cmds
    end,
    -- complete bang command names
    ["^Git!%s+([-%w]*)$"] = function(compl_opts)
      return compl_opts.match, { 'log' }
    end,
    -- complete range command names
    ["^'<,'>Git%s+([-%w]*)$"] = function(compl_opts)
      return compl_opts.match, { 'annotate', 'log' }
    end,
    -- complete repo relative file paths for add, mv, and rm
    ['^Git%s+add%s+.*([-/%w]*)$'] = complete_filepath,
    ['^Git%s+mv%s+.*([-/%w]*)$'] = complete_filepath,
    ['^Git%s+rm%s+.*([-/%w]*)$'] = complete_filepath,
    -- complete branch name in log expansions
    ['^Git%s+log%s+.*diff:([-/%w]*)'] = complete_branch('diff:'),
    ['^Git%s+log%s+.*in:([-/%w]*)'] = complete_branch('in:'),
    ['^Git%s+log%s+.*out:([-/%w]*)'] = complete_branch('out:'),
    -- complete stash action
    ['^Git%s+stash%s+(%w*)$'] = function(compl_opts)
      return compl_opts.match, {
        'apply', 'branch', 'clear', 'create',
        'drop', 'list', 'pop', 'push', 'show',
      }
    end,
    -- complete stash references
    ['^Git%s+stash%s+(%w+%s%S*)'] = function(compl_opts)
      local match = compl_opts.match
      local actions = { 'apply', 'branch', 'drop', 'pop', 'show'}
      local action = match:match('^%w+')
      if vim.list_contains(actions, action) then
        local stashes = M.git('stash list')
        if stashes then
          local refs = vim.tbl_map(function(r)
            return r:match('^stash@{%d+}')
          end, vim.fn.split(stashes, '\n'))
          return match:match('%w+%s(%S)'), refs
        end
      end
      return match, {}
    end,
  }

  for _, alias in ipairs(vim.tbl_keys(config.complete or {})) do
    completions['^Git%s+' .. alias .. '%s+([-/%w]*)$'] = function(compl_opts)
      local compl = config.complete[alias]
      local values
      if compl == 'branch' then
        _, values = complete_branch()(opts)
      elseif compl == 'filepath' then
        _, values = complete_filepath(opts)
      end
      return compl_opts.match, values
    end
  end

  for pattern, values in pairs(completions) do
    local match = pre:match(pattern)
    if match then
      opts.match = match:gsub('%-', '%%-')
      local compl_pattern, compls = values(opts)
      compls = compls or {}
      for _, value in ipairs(compls) do
        if value:match('^' .. compl_pattern) then
          results[#results + 1] = value
        end
      end
      break
    end
  end

  table.sort(results)
  return results
end

M.init = function(init_opts)
  config = init_opts or {}
  vim.api.nvim_create_user_command(
    'Git',
    function(opts)
      if not vim.fn.executable('git') then
        error('git executable not found in your path.')
        return
      end

      local command = commands[opts.fargs[1]]
      -- store a copy of the original args
      opts.fargs_orig = vim.list_slice(opts.fargs, 1, #opts.fargs)
      -- expand %
      opts.fargs = vim.tbl_map(function(a)
        if a == '%' then
          local _, path = file()
          return path and path or a
        end
        return a
      end, opts.fargs)
      opts.args = vim.fn.join(opts.fargs, ' ')

      if opts.bang and (not command or command ~= log)
      then
        error('Only Git! log supports bang usage.')
        return
      end

      if opts.range ~= 0 and
         (not command or (command ~= annotate and command ~= log))
      then
        error('Only Git annotate and log support a range.')
        return
      end

      if command then
        table.remove(opts.fargs, 1)
        opts.args = vim.fn.join(opts.fargs, ' ')
        command(opts)
      else
        term('git ' .. opts.args, {
          echo = 'running: git ' .. opts.args .. ' ...\n',
          on_exit = function(term_bufnr, exit_code)
            -- when removing the current file, remove the buffer as well
            if opts.args:match('^rm%s') and
               opts.fargs_orig[#opts.fargs_orig] == '%' and
               exit_code == 0
            then
              vim.cmd.winc('p')
              vim.schedule(function()
                -- custom command!
                vim.cmd('BufferDelete')
                vim.cmd(vim.fn.bufwinnr(term_bufnr) .. 'winc w')
              end)
            end

            if vim.fn.bufwinnr(status_name) ~= -1 then
              status({ focus = false })
            end
          end
        })
      end
    end,
    {
      bang = true,
      nargs = '+',
      range = true,
      complete = complete,
    }
  )

  vim.keymap.set('ca', 'git', function()
    local abbrev = 'git'
    local type = vim.fn.getcmdtype()
    local pos = vim.fn.getcmdpos()
    local cmdl = vim.fn.getcmdline():sub(1, pos)
    ---@diagnostic disable-next-line: redundant-parameter
    local char = vim.fn.nr2char(vim.fn.getchar(1))
    if type == ':' and
       char:match('[%!%s\r]') and
       (cmdl == 'git' or cmdl == "'<,'>git")
    then
      return 'Git'
    end
    return abbrev
  end, { expr = true })

  vim.keymap.set('n', '<leader>ga', ':Git annotate<cr>', { silent = true })
  vim.keymap.set('n', '<leader>gl', ':Git log<cr>', { silent = true })
  vim.keymap.set('n', '<leader>gs', ':Git status<cr>', { silent = true })
end

return M
