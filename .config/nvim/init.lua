-- options {{{
vim.opt.guicursor = (
  'n-c-sm:block-TermCursor,' ..
  'i-ci-ve:ver25-TermCursor,' ..
  'r-cr-o:hor20-TermCursor,v:block-VisualCursor'
)
vim.opt.clipboard = 'unnamedplus'
vim.opt.complete:remove({ 'i', 't', 'u' })
vim.opt.completeopt = { 'menuone', 'longest', 'preview' }
vim.opt.expandtab = true
vim.opt.fileformats:append('mac')
vim.opt.fillchars = { fold = ' ' }
vim.opt.grepprg = 'rg --vimgrep'
vim.opt.list = true
vim.opt.listchars = { precedes = '<', extends = '>', tab = '>-', trail = '\\u25e6' }
vim.opt.number = true
vim.opt.scrolloff = 10
vim.opt.shell = 'bash -l'
vim.opt.shiftwidth = 2
vim.opt.sidescrolloff = 20
vim.opt.signcolumn = 'number'
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.switchbuf = 'useopen'
vim.opt.tabstop = 2
vim.opt.timeoutlen = 500
vim.opt.updatetime = 1000
vim.opt.winborder = 'rounded'
vim.opt.wildignore:append({
  '*.pyc',
  '*.pyo',
  '*/__pycache__',
  '*/__pycache__/*',
  '*.so',
})
vim.opt.wildmode = { 'longest:full', 'full' }
vim.opt.termguicolors = true

if vim.env.VIRTUAL_ENV then
  -- use the system python which should have the neovim module installed
  vim.g.python3_host_prog = '/usr/bin/python'
end
-- }}}

-- statusline {{{
-- diable nvim's default qf status line, which for some reason can also bleed
-- out to non-qf windows
vim.g.qf_disable_statusline = true

vim.opt.statusline =
  '%<%{%v:lua._status_left()%} %h%r%=%-10.' .. -- left
  '(%{%v:lua._status_right()%} %l,%c%V b=%n,w=%{winnr()}/%{win_getid()}%) %P' -- right
local severities = {
  [vim.diagnostic.severity.ERROR] = 'DiagnosticStatusError',
  [vim.diagnostic.severity.WARN] = 'DiagnosticStatusWarn',
  [vim.diagnostic.severity.INFO] = 'DiagnosticStatusInfo',
  [vim.diagnostic.severity.HINT] = 'DiagnosticStatusHint',
}
function _status_left() ---@diagnostic disable-line: lowercase-global
  local curwinid = vim.fn.str2nr(vim.g.actual_curwin)
  local winid = vim.fn.win_getid()
  local name = vim.fn.bufname()
  if name == '' then
    local wininfo = vim.fn.getwininfo(winid)[1]
    if wininfo.quickfix == 1 then
      local qf_title = vim.w.quickfix_title or ''
      if wininfo.loclist == 1 then
        name = '[Location List] ' .. qf_title
      else
        name = '[Quickfix] ' .. qf_title
      end
    else
      name = '[No Name]'
    end
  end
  local stl = name .. (vim.bo.modified and ' +' or '')
  if curwinid == winid then
    -- check if the file exists and highlight if not
    if vim.fn.bufname() ~= '' and
       vim.bo.buftype == '' and
       not vim.uv.fs_stat(name) then
      stl = '%#StatusLineMissingFile#' .. stl .. ' [missing] %*'
    end

    -- show the max diagnostic severity in the statusline
    if vim.b.max_diagnostics ~= nil then
      local max_severity = nil
      for _, diagnostic in pairs(vim.b.max_diagnostics) do
        if not max_severity or diagnostic.severity < max_severity then
          max_severity = diagnostic.severity
        end
      end
      if max_severity then
        local hi = severities[max_severity]
        stl = '%#' .. hi .. '#' .. stl .. '%*'
      end
    end
  end

  local stl_addl = ''
  -- for csv files, display which column the cursor is in
  if vim.bo.ft == 'csv' then
    local ok, csv = pcall(require, 'csv')
    if ok then
      local column = csv.column()
      stl_addl = '[col: ' .. csv.column_name(column) .. ' (' .. column .. ')]'
    end
  end

  -- show in the status line if the file is in dos format
  if vim.bo.ff ~= 'unix' then
    stl_addl = '[' .. vim.bo.ff .. '] ' .. stl_addl
  end

  if curwinid == winid then
    stl_addl = '%#StatusLineFF#' .. stl_addl .. '%*'
  end

  return stl .. ' ' .. stl_addl
end

function _status_right() ---@diagnostic disable-line: lowercase-global
  local curwinid = vim.fn.str2nr(vim.g.actual_curwin)
  local winid = vim.fn.win_getid()
  local stl_search = ''
  if curwinid == winid then
    local ok, count = pcall(vim.fn.searchcount)
    if ok and next(count) then
      local pattern = vim.fn.substitute(vim.fn.getreg('/'), '%', '%%', 'g')
      stl_search =
        '/' .. pattern .. '/ [' ..
        '%#CurSearchStatus#' .. count.current ..
        '%#StatusLine#/' ..
        '%#SearchStatus#' .. count.total ..
        '%#StatusLine#' .. ']'
    end
  end
  return stl_search
end -- }}}

-- tabline {{{
vim.opt.tabline = '%!v:lua._tab()'
function _tab() ---@diagnostic disable-line: lowercase-global
  local num_tabs = vim.fn.tabpagenr('$')
  if num_tabs == 1 and not vim.fn.exists('t:tab_name') then
    return ''
  end

  local tabline = ''
  local curr_tab = vim.fn.tabpagenr()
  for tabnr = 1,num_tabs do
    tabline = tabline .. (tabnr == curr_tab and '%#TabLineSel#' or '%#TabLine#')
    local name = ''
    local winnr = vim.fn.tabpagewinnr(tabnr)
    local winid = vim.fn.win_getid(winnr)
    if not vim.api.nvim_win_get_config(winid).zindex then
      local bufnr = vim.fn.tabpagebuflist(tabnr)[winnr]
      local buftype = vim.bo[bufnr].buftype
      if buftype ~= 'nofile' and buftype ~= 'quickfix' then
        name = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ':t')
        if name == '' then
          name = '[No Name]'
        end
      end
    end

    local tab_name = vim.fn.gettabvar(tabnr, 'tab_name')
    if tab_name ~= '' then
      if tabnr == curr_tab then
        -- NOTE: avoid system calls since they could cause annoying flickering
        local dotgit = vim.fn.finddir(
          '.git',
          vim.fn.escape(vim.fn.getcwd(), ' ') .. ';'
        )
        if dotgit ~= '' then
          local lines = vim.fn.readfile(dotgit .. '/HEAD')
          if #lines > 0 then
            local branch = lines[1]:gsub('ref: refs/heads/', '')
            if branch ~= '' and branch ~= lines[1] then
              branch = '%#TabLineSelBranch#' .. branch .. '%#TabLineSel#'
              tab_name = tab_name .. ':' .. branch
            end
          end
        end
      end
      name = tab_name .. ' ' .. name
    end

    tabline = tabline .. ' ' .. name
    if tabnr ~= num_tabs then
      tabline = tabline .. '%#TabLine# | '
    end
  end

  return tabline .. '%#TabLineFill#%T'
end -- }}}

-- mappings {{{

vim.g.mapleader = ','

-- scrolling just the viewpane
vim.keymap.set('n', '<c-j>', '<c-e>')
vim.keymap.set('n', '<c-k>', '<c-y>')

-- navigate windows
vim.keymap.set('n', '<tab><tab>', ':winc p<cr>', { silent = true })
vim.keymap.set('n', '<tab>j', ':winc j<cr>', { silent = true })
vim.keymap.set('n', '<tab>J', ':winc b<cr>', { silent = true })
vim.keymap.set('n', '<tab>k', ':winc k<cr>', { silent = true })
vim.keymap.set('n', '<tab>K', ':winc t<cr>', { silent = true })
vim.keymap.set('n', '<tab>l', ':winc l<cr>', { silent = true })
vim.keymap.set('n', '<tab>h', ':winc h<cr>', { silent = true })
vim.keymap.set('n', '<tab>m', ':winc x | winc j<cr>', { silent = true })
vim.keymap.set('n', '<tab>M', function()
  local prev = vim.fn.winnr() - 1
  vim.cmd(prev .. 'winc x | winc k')
end, { silent = true })

-- tab nav/manipulation mappings
vim.keymap.set('n', 'gh', ':tabprev<cr>', { silent = true })
vim.keymap.set('n', 'gl', ':tabnext<cr>', { silent = true })
vim.keymap.set('n', 'gH', ':-tabmove<cr>', { silent = true })
vim.keymap.set('n', 'gL', ':+tabmove<cr>', { silent = true })

-- back tick works like single quote for jumping to a mark, but restores the
--column position too.
vim.keymap.set('n', '\'', '`')

-- use - to jump to front of text since _ requires an extra key
vim.keymap.set('n', '-', '_')

-- allow g. to move back through the change list (like the single use '.)
vim.keymap.set('n', 'g.', 'g;')
-- map '. to use changelist operation so that if the location isn't the one I
-- want, I don't have to hit g. twice just to get to the next change in the
-- list
vim.keymap.set('n', '\'.', function()
  -- nvim throws an error if already at the head of the list
  pcall(function() vim.cmd.norm('999g,') end)
end)

-- redraw screen + clear search highlights + update diffs
vim.keymap.set('n', '<c-l>', ':nohl | diffu<cr><c-l>', { silent = true })

-- toggle wrapping of text
vim.keymap.set('n', '<leader>wt', ':let &wrap = !&wrap<cr>', { silent = true })

-- toggle diff of the current buffer
vim.keymap.set('n', '<leader>dt', function()
  vim.cmd(vim.wo.diff and 'diffoff' or 'diffthis')
end)

-- modified version of '*' which doesn't move the cursor
vim.keymap.set(
  'n',
  '*',
  '"syiw<esc>:let @/ = "\\\\<" . @s . "\\\\>"<cr>' ..
  ':set hls | call histadd("search", getreg("/"))<cr>',
  { silent = true }
)

-- toggle spelling with <c-z> (normal or insert mode)
vim.keymap.set('n', '<c-z>', function()
  vim.wo.spell = not vim.wo.spell
  local state = vim.wo.spell and 'on' or 'off'
  vim.api.nvim_echo(
    {{ 'spell check: ' .. state, 'WarningMsg' }}, false, {}
  )
end)

-- preserve the " register when pasting over a visual selection
vim.keymap.set('x', 'p', 'P')

-- swap 2 words
vim.keymap.set('n', '<leader>ws', function()
  local pos = vim.fn.getpos('.')
  vim.cmd('normal! "_yiw')
  vim.cmd('keepp keepj s/\\(\\%#\\w\\+\\)\\(\\_W\\+\\)\\(\\w\\+\\)/\\3\\2\\1/')
  vim.fn.setpos('.', pos)
end)

vim.keymap.set('n', 'gf', ':Grep --files<cr>', { silent = true })
vim.keymap.set('n', 'gF', ':Grep! --files<cr>', { silent = true })

-- allow ctrl-v to paste in command line and insert modes
-- (use ctrl-q as an alternative to insert literal ctrl characters)
vim.keymap.set({ 'c', 'i' }, '<c-v>', function()
  -- using feedkeys to ensure any vim ctrl values that may be in the register
  -- are inserted literally instead of being evaluated (eg. <cr>)
  vim.fn.feedkeys(vim.fn.getreg('+'))
end)


-- alt-esc to close all floating windows
vim.keymap.set('n', '<a-esc>', function()
  for winnr = vim.fn.winnr('$'), 1, -1 do
    local winid = vim.fn.win_getid(winnr)
    if vim.api.nvim_win_get_config(winid).zindex ~= nil then
      vim.api.nvim_win_close(winid, true)
    end
  end
end)

-- }}}

-- commands {{{

-- print or jump to an absolute offset in the file
vim.api.nvim_create_user_command('Offset', function(opts)
  local eol = vim.bo.ff == 'dos' and 2 or 1
  if opts.args == '' then
    local offset = vim.fn.col('.')
    local line = vim.fn.line('.')
    while line ~= 1 do
      line = line - 1
      offset = offset + #vim.fn.getline(line) + eol
    end
    vim.print('Offset: ' .. offset - 1)
  else
    local target = tonumber(opts.args)
    local offset = 0
    local line = 1
    local col = 1
    local last = vim.fn.line('$')
    while offset < target and line <= last do
      offset = offset + #vim.fn.getline(line) + eol
      line = line + 1
    end

    line = line - 1
    if offset > target then
      local diff = offset - target
      col = #vim.fn.getline(line) - diff + 2
    end
    vim.fn.cursor(line, col + 1)
  end
end, { nargs = '?' })

-- }}}

-- abbreviations {{{

vim.keymap.set('ca', 'ln', function()
  local type = vim.fn.getcmdtype()
  local cmdl = vim.fn.getcmdline():sub(1, vim.fn.getcmdpos())
  if type == ':' and cmdl == 'ln' then
    return 'lnext'
  end
  return 'ln'
end, { expr = true })

-- }}}

-- autocmds {{{

-- follow symlinks to open the actual file
vim.api.nvim_create_autocmd('BufReadPost', {
  pattern = '*',
  callback = function()
    local buf = vim.fn.bufname()
    local path = vim.fn.resolve(buf)
    if path ~= buf then
      vim.cmd('enew')
      vim.cmd('bwipeout #')
      vim.cmd('edit ' .. path)
      vim.cmd('filetype detect')
      vim.cmd('doautocmd BufWinEnter')
    end
  end
})

-- when editing a file, jump to the last known cursor position.
vim.api.nvim_create_autocmd('BufWinEnter', {
  pattern = '*',
  callback = function()
    -- ignore some files
    local bufname = vim.fn.bufname()
    if bufname:match('/%.git/') ~= nil then return end
    if bufname:match('notes.md$') ~= nil then return end

    -- move cursor (g`"), open folds (zO), center the cursor line (zz)
    vim.cmd('silent! normal! g`"zOzz')
  end
})
-- ensure the last position is persisted before deleting a buffer
vim.api.nvim_create_autocmd('BufDelete', {
  pattern = '*',
  callback = function() vim.cmd('wshada') end,
})

-- disable the netrw plugin and raise an error attempting to open a directory
vim.g.loaded_netrwPlugin = 1
vim.api.nvim_create_autocmd('BufWinEnter', {
  pattern = '*',
  callback = function()
    if vim.fn.isdirectory(vim.fn.bufname()) == 1 then
      local bufnr = vim.fn.bufnr()
      vim.schedule(function()
        vim.api.nvim_echo(
          {{ 'Attempting to edit a directory', 'Error' }}, false, {}
        )
      end)
      vim.api.nvim_create_autocmd('BufWinLeave', {
        buffer = bufnr,
        once = true,
        callback = function()
          vim.schedule(function()
            vim.cmd('silent! ' .. bufnr .. 'bwipeout')
          end)
        end,
      })
      return
    end
  end
})

-- disallow writing to read only files
vim.api.nvim_create_autocmd('BufRead', {
  pattern = '*',
  callback = function()
    if vim.bo.readonly and vim.bo.buftype == '' then
      vim.bo.modifiable = false
    end
  end
})

-- only highlight cursor line / color column of the current window, making it
-- easier to pick out which window has focus
vim.api.nvim_create_autocmd('WinLeave', {
  pattern = '*',
  callback = function()
    vim.wo.cursorline = false
    vim.wo.colorcolumn = ''
  end
})
vim.api.nvim_create_autocmd({ 'VimEnter', 'WinEnter', 'FileType' }, {
  pattern = '*',
  callback = function()
    -- using schedule since sometimes WinEnter has the wrong target buffer
    -- (possibly a bug with something in my env triggering the event too soon)
    vim.schedule(function()
      -- don't show the colorcolumn for certain file types or files that can't be
      -- edited
      local ignore_ft = { 'qf' }
      if not vim.list_contains(ignore_ft, vim.bo.ft) and
         not vim.bo.readonly and
         vim.bo.modifiable and
         vim.bo.buftype == ''
      then
        vim.wo.colorcolumn = '82'
      end

      local ignore_bt = { 'prompt', 'terminal' }
      if not vim.list_contains(ignore_bt, vim.bo.buftype) then
        if vim.bo.ft ~= 'man' then
          vim.wo.number = true
        end
        vim.wo.cursorline = true
      end
    end)
  end
})

-- allow opening a file at a line number: foo/bar.txt:12
vim.api.nvim_create_autocmd('BufReadCmd', {
  pattern = '*:*',
  callback = function(args)
    local path, line = unpack(vim.fn.split(args.match, ':'))
    if not string.match(line, '^%d+$') then
      return
    end

    -- make the path relative if possible
    path = vim.fn.fnamemodify(path, ':.')

    if vim.fn.filereadable(path) == 1 then
      local tempbufnr = vim.fn.bufnr()
      if vim.fn.bufexists(path) == 0 then
        vim.cmd('edit ' .. path)
        vim.cmd('filetype detect')
      else
        local bufnr = vim.fn.bufnr(path)
        local winnr = vim.fn.bufwinnr(bufnr)
        if winnr == -1 then
          vim.cmd('new +' .. bufnr .. 'buffer')
        else
          vim.cmd(winnr .. 'winc w')
        end
      end
      vim.cmd('silent ' .. line)
      vim.cmd('normal zz')
      -- set last known position so that our BufWinEnter autocmd doesn't
      -- override our cursor position
      vim.cmd([[ normal! m" ]])
      vim.cmd('doautocmd BufReadPost')
      vim.cmd('doautocmd BufWinEnter')
      vim.cmd('doautocmd WinEnter')
      vim.cmd(tempbufnr .. 'bwipeout!')
    end
  end
})

-- temporarily change the color of the current search highlight when wrapping
vim.api.nvim_create_autocmd('SearchWrapped', {
  callback = function()
    local group = vim.api.nvim_create_augroup('search_wrap', { clear = false })
    vim.api.nvim_set_hl(0, 'CurSearch', { link = 'CurSearchWrap' })
    vim.api.nvim_clear_autocmds({ event = 'CursorMoved', group = group })
    vim.schedule(function()
      vim.api.nvim_create_autocmd({ 'CursorMoved' }, {
        group = group,
        once = true,
        callback = function()
          vim.api.nvim_set_hl(0, 'CurSearch', { link = 'CurSearchMain' })
        end,
      })
    end)
  end
})

-- setup terminal buffers
vim.api.nvim_create_autocmd('TermOpen', {
  callback = function()
    vim.wo.cursorline = false
    vim.wo.cursorcolumn = false
    vim.wo.number = false
    vim.cmd.startinsert()
    -- mapping to exit terminal mode
    vim.keymap.set('t', '<esc><esc>', '<c-\\><c-n>', { buffer = true })
    -- restore window settings when the term buffer is removed from the window
    vim.api.nvim_create_autocmd('BufWinLeave', {
      buffer = vim.fn.bufnr(),
      callback = function(args)
        if vim.fn.winnr() == vim.fn.bufwinnr(args.buf) then
          vim.wo.number = true
          -- let our WinEnter autocmd do the rest of the work
          vim.cmd.doautocmd('WinEnter')
        end
      end
    })
  end
})

-- setup floating windows to resize with nvim
-- (currently assumes there will be just one)
local resize_floating_group = vim.api.nvim_create_augroup('resize_floating', {})
vim.api.nvim_create_autocmd('WinNew', {
  callback = function()
    local ratios = function(config)
      local width_ratio = config.width / vim.o.columns
      local height_ratio = config.height / vim.o.lines
      return { width = width_ratio, height = height_ratio}
    end

    local winid = vim.fn.win_getid()
    local config = vim.api.nvim_win_get_config(winid)
    if config.zindex then
      vim.w[winid].size_ratios = ratios(config)
      vim.api.nvim_clear_autocmds({ group = resize_floating_group })
      vim.api.nvim_create_autocmd('VimResized', {
        group = resize_floating_group,
        callback = function()
          if not vim.api.nvim_win_is_valid(winid) then
            vim.api.nvim_clear_autocmds({ group = resize_floating_group })
            return
          end

          local size_ratios = vim.w[winid].size_ratios
          local winnr = vim.api.nvim_win_get_number(winid)
          local width = math.floor(vim.o.columns * size_ratios.width)
          local height = math.floor(vim.o.lines * size_ratios.height)
          vim.cmd('vertical ' .. winnr .. 'resize ' .. width)
          vim.cmd(winnr .. 'resize ' .. height)
          vim.w[winid].size_ratios = ratios(vim.api.nvim_win_get_config(winid))
        end
      })
    end
  end
})

-- }}}

-- plugins {{{

require('comment').init()
require('diff').init()
require('git').init(
  { -- {{{
    branch_merge = 'complete',
    complete = {
      blogin = 'branch',
      blogout = 'branch',
      ['branch-hotfix'] = 'branch',
      cp = 'branch',
      mergein = 'branch',
      pr = 'branch',
      view = 'filepath',
    },
    hooks = {
      pre_branch_create = function(git, name)
        local work = require('work')
        local issue_id = name:match('^(%d+)-.*')
        if not issue_id then
          local result = git.confirm(
            'Branch name not in format: <issue_id>-<desc>, create anyway?',
            '&yes\n&no',
            nil,
            'Warning'
          )
          if result ~= 1 then
            return ''
          end
          return true
        end

        local issue_json = git.git('ticket-info ' .. issue_id)
        local issue = vim.json.decode(issue_json)
        if issue.assignee.email ~= work.email then
          if issue.assignee.email == vim.NIL then
            return 'Issue is currently unassigned.'
          end
          return 'Issue is assigned to another dev: ' .. issue.assignee.name
        end
        if issue.status ~= 'New' then
          return 'Issue is not in a New state: ' .. issue.status
        end

        vim.print('Ticket: ' .. issue.title)
        local current = git.git('rev-parse --abbrev-ref HEAD')
        local msg = 'Create new branch ' .. name .. ' from ' .. current .. '?'
        local msg_type = not git.is_protected(current) and 'Warning' or nil
        local result = git.confirm(msg, '&yes\n&no', nil, msg_type)
        if result ~= 1 then
          return ''
        end
        return true
      end,
      pre_commit = function(git, branch)
        -- check the existence of repository ticket patterns to determine if this
        -- is a work repo or not
        local repo = git.git('rev-parse --show-toplevel'):match('.*/(.*)')
        local work_repos = git.git(
          'config --get ticket.' .. repo .. '.pattern',
          { quiet = true }
        )
        if not work_repos then
          return true
        end

        local issue_id = branch:match('^(%d+)-.*')
        if not issue_id then
          return git.confirm(
            'Are you sure you want to commit to a non-topic branch?',
            '&yes\n&no',
            nil,
            'Warning'
          ) == 1
        end

        local issue_json = git.git('ticket-info ' .. issue_id)
        local issue = vim.json.decode(issue_json)
        if issue.status ~= 'New' then
           vim.print('Ticket (' .. issue.status .. '): ' .. issue.title)
          return git.confirm(
            'Ticket is not in a New state, are you sure you want to commit to it?',
            '&yes\n&no',
            nil,
            'Warning'
          ) == 1
        end

        return true
      end
    },
  } -- }}}
)
require('colorscheme').init()
require('csv').init()
require('grep').init()
require('indentdetect').init()
require('lsp').init()
require('maximize').init()
require('mergetool').init()
require('notes').init()
require('open').init()
require('qf').init()
require('regex').init()
require('tab').init()
require('tabcomplete').init()
require('virtualedit').init()
require('wrap').init()

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath) ---@diagnostic disable-line: undefined-field

require('lazy').setup( ---@diagnostic disable-line: undefined-field
  'spec',     -- load plugin specs from .config/nvim/lua/spec/*.lua
  {           -- lazy.nvim config options
    change_detection = {
      enable = false,
      notify = false,
    },
    ui = { border = 'rounded' },
  }
)

-- }}}

-- load any work specific settings
local loaded, err = pcall(require, 'work')
if not loaded and err ~= nil and not err:match("module 'work' not found") then
  vim.schedule(function()
    vim.api.nvim_echo({{ err, 'Error' }}, true, {})
  end)
end

-- vim:fdm=marker
