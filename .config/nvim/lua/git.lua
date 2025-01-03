M = {}

local error = function(msg, hl)
  vim.api.nvim_echo({{ msg, hl or 'Error' }}, true, {})
end

M.git = function(args, exec)
  local cmd = 'git --no-pager ' .. args
  local result
  if exec then
    local outfile = vim.fn.tempname()
    cmd = '!' .. cmd .. ' 2>&1| tee "' .. outfile .. '"'
    vim.cmd(vim.fn.escape(cmd, '%'))
    result = vim.fn.join(vim.fn.readfile(outfile), "\n")
    vim.fn.delete(outfile)
  else
    result = vim.fn.system(cmd, exec)
  end

  if vim.v.shell_error ~= 0 or result:match('^fatal:') then
    error('Error executing command: ' .. cmd .. '\n' .. result)
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

  local root
  local path = vim.fn.resolve(vim.fn.expand('%:p'))
  if vim.fn.isdirectory(path) == 0 then
    path = vim.fn.fnamemodify(path, ':h')
  end

  -- try submodule first
  local submodule = vim.fn.findfile('.git', path .. ';')
  if submodule ~= '' and
     vim.fn.readfile(submodule, '', 1)[1]:match('^gitdir:')
  then
    return vim.fn.fnamemodify(submodule, ':p:h')
  end

  -- try standard .git dir
  local found = vim.fn.finddir('.git', path .. ';')
  if found ~= '' then
    -- handle result relative to cwd
    if found == '.git' then
      found = vim.fn.getcwd() .. '/.git'
    end
    root = vim.fn.fnamemodify(found, ':p:h:h') .. '/'
  end

  return root
end

local repo_settings = function()
  local root = repo()
  if root:match('/$') then
    root = root:sub(1, #root - 1)
  end
  -- escape dashes for matching
  root = root:gsub('%-', '%%-')
  for key, settings in pairs(vim.g.git_repo_settings) do
    key = vim.fn.expand(key)
    if key:match('^' .. root .. '$') then
      return settings
    end
  end
  return {}
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
      -- don't use cached the revision if we are in the actual file since there
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

local me = {}
local log_bufname = 'git log'
local annotate_augroup = vim.api.nvim_create_augroup('git_annotate', {})
local function annotate(opts)
  if vim.fn.bufname() == log_bufname then
    return
  end

  local bufnr = vim.fn.bufnr()
  local sign_group = 'git_annotate'

  if vim.b.git_annotations then
    vim.api.nvim_clear_autocmds({ buffer = bufnr, group = annotate_augroup })
    vim.fn.sign_unplace('git_annotate')
    vim.b.git_annotations = nil
    vim.cmd.echo() -- clear any existing annotation info
    return
  end

  local wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1]
  local first = wininfo['topline']
  local last = wininfo['botline']
  local root, path, revision = file(opts.path)
  if not path then
    return
  end

  revision = opts.revision or revision
  local result = M.git(
    'annotate "' .. path .. '"' ..
    (revision and (' ' .. revision) or '') ..
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
  if vim.bo.modifiable then
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

local window = function(name, open, opts)
  opts = opts or {}

  local winnr = vim.fn.bufwinnr(name)
  if winnr ~= -1 then
    vim.cmd(winnr .. 'winc w')
  else
    vim.cmd(open .. ' ' .. vim.fn.escape(name, ''))

    -- detach all lsp clients for this temp buffer
    local bufnr = vim.fn.bufnr()
    local clients = vim.lsp.get_clients({ buffer = bufnr })
    for _, client in ipairs(clients) do
      if vim.lsp.buf_is_attached(bufnr, client.id) then
        vim.lsp.buf_detach_client(bufnr, client.id)
      end
    end
  end

  if opts.lines then
    vim.bo.readonly = false
    vim.bo.modifiable = true
    vim.cmd('silent 1,$delete _')
    vim.fn.append(1, opts.lines)
    vim.cmd('silent 1,1delete _')
    vim.fn.cursor(1, 1)
    vim.bo.modified = false
    vim.bo.readonly = true
    vim.bo.modifiable = false
    vim.bo.swapfile = false
    vim.bo.buflisted = false
    vim.bo.buftype = 'nofile'
    vim.bo.bufhidden = 'wipe'
    vim.cmd('doautocmd BufReadPost')

    -- let nvim diff code attempt to sync the cursor position
    if opts.diff_sync then
      vim.cmd.diffthis()
      vim.cmd.winc('p')

      -- don't discrupt an existing diff
      local other_diff = vim.wo.diff
      if not other_diff then
        vim.cmd.diffthis()
      end

      -- opening the diff folds seems to be necessary, at least of the original
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
end

M.show = function(opts)
  if vim.fn.bufname() == log_bufname then
    return
  end

  opts.revision = opts.revision or (opts.fargs and opts.fargs[2]) or 'HEAD'

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
  window(git_file, opts.open or 'new', {
    lines = vim.fn.split(result, '\n'),
    diff_sync = opts.diff_sync or not opts.path,
  })
  set_info(root, path, target_revision)
  return true
end

local diff_augroup = vim.api.nvim_create_augroup('git_diff', {})
local diff = function(opts)
  if vim.fn.bufname() == log_bufname then
    return
  end

  opts.revision = opts.revision or (opts.fargs and opts.fargs[2]) or 'HEAD'

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
    vim.cmd.diffthis()
    local diffbufnr = vim.fn.bufnr()

    vim.b.git_filename = filename
    vim.b.git_diff = true

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
    '+ %s %s (%s)%s %s',
    details.revision,
    details.author, ---@diagnostic disable-line: redundant-parameter
    details.age,    ---@diagnostic disable-line: redundant-parameter
    details.refs,   ---@diagnostic disable-line: redundant-parameter
    details.comment ---@diagnostic disable-line: redundant-parameter
  )
end

local log_revision = function()
  local lnum = vim.fn.search('^[+-] \\w\\+', 'bcnW')
  local line = vim.fn.getline(lnum)
  return vim.fn.substitute(line, '[+-] \\(\\w\\+\\) .*', '\\1', '')
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

  local values = vim.fn.split(result, '|')
  local details = {
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
  vim.bo.readonly = false
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
    local end_ = vim.fn.search('^[+-] \\w\\+', 'nW') - 1
    if end_ == -1 then
      end_ = vim.fn.line('$')
    end
    vim.cmd(lnum + 1 .. ',' .. end_ .. 'delete _')
    vim.fn.setpos('.', pos)
  end
  vim.bo.modifiable = false
  vim.bo.readonly = true
end

local log_files = function()
  local lnum = vim.fn.line('.')
  local line = vim.fn.getline(lnum)
  local revision = log_revision()

  vim.bo.modifiable = true
  vim.bo.readonly = false
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
    local end_ = vim.fn.search('^[+-] \\w\\+', 'cnW') - 1
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
  vim.bo.readonly = true
end

local log_open = function()
  local open = 'new'
  if vim.b.git_filename then
    local winnr = vim.fn.bufwinnr(vim.b.git_filename)
    if winnr ~= -1 then
      vim.cmd(winnr .. 'winc w')
    else
      open = 'above new'
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

  local open = log_open()
  window('git_' .. revision .. '.patch', open, {
    lines = vim.fn.split(result, '\n')
  })
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

  if line:match('^[+-] %w+') then
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
        open = 'above new',
      })

    -- deleted file
    elseif link == 'D' then
      local path = vim.fn.substitute(line, regex, '\\1', '')
      local previous = get_previous_revision(path, revision)
      M.show({
        path = path,
        revision = previous,
        open = 'above new',
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

    -- make relative to cwd if possible
    local cwd = vim.fn.getcwd()
    if string.sub(cwd, -1) ~= '/' then
      cwd = cwd .. '/'
    end
    local index = string.find(filename, cwd, 1, true)
    if index == 1 then
      filename = string.sub(filename, #cwd + 1)
    end

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
  local root, path
  local name = log_bufname
  local filename
  if vim.fn.bufname() == name and vim.b.git_filename then
    filename = vim.b.git_filename
  else
    filename = vim.fn.expand('%:p')
    if filename == '' then
      filename = nil
    end
  end

  local log_cmd = 'log --pretty=tformat:"%h|%an|%ar|%d|%s|"'
  if opts.log_args then
    root = repo()
    log_cmd = log_cmd .. ' ' .. opts.log_args
  elseif filename then
    root, path, _ = file(filename)
  else
    root = repo()
  end

  if not root then
    return
  end

  if path then
    log_cmd = log_cmd .. ' --follow ' .. path
  end

  local result = M.git(log_cmd, opts.exec)
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

  for _, line in ipairs(vim.fn.split(result, '\n')) do
    local values = vim.fn.split(line, '|')
    lines[#lines + 1] = log_line({
      revision = values[1],
      author = values[2],
      age = values[3],
      refs = values[4],
      comment = values[5],
    })
  end

  window(name, 'botright 10sview', { lines = lines })
  vim.wo.statusline = '%<%f %=%-10.(%l,%c%V%) %P'
  vim.wo.wrap = false
  vim.wo.winfixheight = true
  vim.cmd.resize(10)
  vim.cmd.doautocmd('WinNew')
  vim.cmd.doautocmd('WinEnter')

  vim.bo.ft = 'git_log'
  vim.cmd('syntax match GitRevision /\\(^[+-] \\)\\@<=\\w\\+/')
  vim.cmd('syntax match GitAuthor /\\(^[+-] \\w\\+ \\)\\@<=.\\{-}\\( (\\)\\@=/')
  vim.cmd('syntax match GitDate /\\(^[+-] \\w\\+ \\w.\\{-}\\)\\@<=(\\d.\\{-})/')
  vim.cmd('syntax match GitRefs /\\(^[+-] \\w\\+ \\w.\\{-} (\\d.\\{-}) \\)\\@<=(.\\{-})/')
  vim.cmd('syntax match GitLink /|\\S.\\{-}|/')
  vim.cmd('syntax match GitFiles /\\(^\\s\\+[+-] \\)\\@<=files\\>/')
  vim.cmd('syntax match GitLogHeaderName /^\\%<4l.\\{-}:/')
  vim.cmd('syntax match GitLogHeader /^\\%<4l.\\{-}: .*/ contains=GitLogHeaderName')

  set_info(root, path, nil)

  local bufnr = vim.fn.bufnr()
  vim.keymap.set('n', '<cr>', log_action, { buffer = bufnr })
  vim.api.nvim_clear_autocmds({ buffer = bufnr, group = log_augroup })
  if filename then
    vim.b.git_filename = filename
    vim.api.nvim_create_autocmd('BufWinLeave', {
      buffer = bufnr,
      group = log_augroup,
      callback = function()
        local winnr = vim.fn.bufwinnr(vim.b.git_filename)
        if winnr ~= -1 then
          vim.schedule(function()
            vim.cmd(winnr .. 'winc w')
            vim.cmd.doautocmd('BufEnter')
          end)
        end
      end,
    })
  end
end

local log_grep = function(type, opts)
  local log_args
  local args = opts.args:match('^[^%s]+%s+(.*)$')
  if not args or args:match('^%s*$') then
    error('Please supply a pattern to search for.', 'WarningMsg')
    return
  end

  args = vim.fn.escape(args, '"')
  if type == 'commits' then
    log_args = '-E "--grep=' .. args .. '"'
  elseif type == 'files' then
    log_args = '--pickaxe-regex "-S' .. args .. '"'
  end

  if not log_args then
    return
  end

  log({
    log_args = log_args,
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

local commands = {
  annotate = annotate,
  diff = diff,
  log = log,
  show = M.show,
  ['grep-commits'] = grep_commits,
  ['grep-files'] = grep_files,
}

M.init = function()
  vim.api.nvim_create_user_command(
    'Git',
    function(opts)
      local command = commands[opts.fargs[1]]
      if not vim.fn.executable('git') then
        error('git executable not found in your path.')
      elseif command then
        command(opts)
      else
        error('Command does not exist: ' .. command)
      end
    end,
    {
      nargs = '+',
      complete = function(_, cmdl, pos)
        local pre = string.sub(cmdl, 1, pos)
        local match = pre:match('^Git%s+([-%w]*)$')
        local results = {}
        if match then
          match = match:gsub('%-', '%%-')
          for k, _ in pairs(commands) do
            if k:match('^' .. match) then
              results[#results + 1] = k
            end
          end
        end
        table.sort(results)
        return results
      end,
    }
  )

  vim.keymap.set('ca', 'git', function()
    local abbrev = 'git'
    local type = vim.fn.getcmdtype()
    local pos = vim.fn.getcmdpos()
    ---@diagnostic disable-next-line: redundant-parameter
    local char = vim.fn.nr2char(vim.fn.getchar(1))
    if type == ':' and pos == #abbrev + 1 and char:match('[%s\r]') then
      return 'Git'
    end
    return abbrev
  end, { expr = true })

  vim.keymap.set('n', '<leader>ga', ':Git annotate<cr>', { silent = true })
  vim.keymap.set('n', '<leader>gl', ':Git log<cr>', { silent = true })
end

return M
