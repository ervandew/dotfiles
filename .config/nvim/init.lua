-- use vim settings in neovim
vim.opt.rtp:prepend('~/.vim/')
vim.cmd('let &packpath = &runtimepath')

-- options {{{
vim.opt.guicursor = (
  'n-c-sm:block-TermCursor,' ..
  'i-ci-ve:ver25-TermCursor,' ..
  'r-cr-o:hor20-TermCursor,v:block-Cursor'
)
vim.opt.clipboard = 'unnamed'
vim.opt.complete:remove({ 'i', 't', 'u' })
vim.opt.completeopt = { 'menuone', 'longest', 'preview' }
vim.opt.expandtab = true
vim.opt.fileformats:append('mac')
vim.opt.fillchars = { fold = ' ' }
vim.opt.list = true
vim.opt.listchars = { precedes = '<', extends = '>', tab = '>-', trail = '-' }
vim.opt.number = true
vim.opt.scrolloff = 5
vim.opt.shiftwidth = 2
vim.opt.sidescrolloff = 10
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.switchbuf = 'useopen'
vim.opt.tabstop = 2
vim.opt.timeoutlen = 500
vim.opt.updatetime = 1000
vim.opt.virtualedit = 'all'
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
vim.opt.statusline = '%<%f%{%v:lua._status()%} %M %h%r%=%-10.(%l,%c%V b=%n,w=%{winnr()}%) %P'
function _status() ---@diagnostic disable-line: lowercase-global
  local stl = ''
  -- show the quickfix title
  if vim.o.ft == 'qf' then
    stl = vim.fn.getqflist({ title = true })
  -- for csv files, display which column the cursor is in
  elseif vim.o.ft == 'csv' then
    if vim.fn.exists(':CSV_WCol') then
      stl = ' [col: ' .. vim.fn.CSV_WCol('Name') .. ' (' .. vim.fn.CSV_WCol() .. ')]'
    end
  end

  -- show in the status line if the file is in dos format
  if vim.o.ff ~= 'unix' then
    stl = ' [' .. vim.o.ff .. ']' .. stl
  end

  if vim.fn.str2nr(vim.g.actual_curwin) == vim.fn.win_getid() then
    return '%#StatusLineFF#' .. stl .. '%*'
  end
  return stl
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
    local buflist = vim.fn.tabpagebuflist(tabnr)
    local winnr = vim.fn.tabpagewinnr(tabnr)
    local name = vim.fn.fnamemodify(vim.fn.bufname(buflist[winnr]), ':t')
    if name == '' then
      name = '[No Name]'
    end

    local tab_name = vim.fn.gettabvar(tabnr, 'tab_name')
    if vim.fn.bufname(buflist[1]):match('^term://.*:ranger.*') then
      name = ''
      tab_name = ''
    end

    if tab_name ~= '' then
      if tabnr == curr_tab then
        local dotgit = vim.fn.finddir(
          '.git',
          vim.fn.escape(vim.fn.getcwd(), ' ') .. ';'
        )
        if dotgit ~= '' then
          local lines = vim.fn.readfile(dotgit .. '/HEAD')
          local branch = #lines > 0 and lines[1]:gsub('ref: refs/heads/', '') or ''
          if branch ~= '' then
            tab_name = tab_name .. '(' .. branch .. ')'
          end
        end
      end
      name = tab_name .. ': ' .. name
    end

    tabline = tabline .. ' %{"' .. name .. '"} '
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
vim.keymap.set('n', '<tab>k', ':winc k<cr>', { silent = true })
vim.keymap.set('n', '<tab>l', ':winc l<cr>', { silent = true })
vim.keymap.set('n', '<tab>h', ':winc h<cr>', { silent = true })
vim.keymap.set('n', '<tab>m', ':winc x<cr>', { silent = true })
vim.keymap.set('n', '<leader>p', ':call v:lua._pick_window()<cr>', { silent = true })
function _pick_window() ---@diagnostic disable-line: lowercase-global {{{
  local max = vim.fn.winnr('$')
  local result = vim.fn.input('Window #: ')
  vim.cmd.mode()
  if result == '' then
    return
  end
  local num = vim.fn.str2nr(result)
  if num < 1 or num > max then
    vim.api.nvim_echo(
      {{ 'Invalid window number: ' .. result, 'WarningMsg' }}, false, {}
    )
    return
  end
  vim.cmd(num .. 'winc w')
end -- }}}

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
vim.keymap.set('n', '<leader>w', ':let &wrap = !&wrap<cr>', { silent = true })

-- toggle diff of the current buffer
vim.keymap.set('n', '<leader>d', function()
  vim.cmd(vim.o.diff and 'diffoff' or 'diffthis')
end)

-- gF is the same as gf + supports jumping to line number (file:100)
vim.keymap.set('n', 'gf', 'gF')
vim.keymap.set('n', 'gF', '<c-w>F')

-- modified version of '*' which doesn't move the cursor
vim.keymap.set(
  'n',
  '*',
  '"syiw<esc>: let @/ = "\\\\<" . @s . "\\\\>"<cr>:set hls<cr>'
)

-- toggle spelling with <c-z> (normal or insert mode)
vim.keymap.set('n', '<c-z>', function()
  vim.o.spell = not vim.o.spell
  local state = vim.o.spell and 'on' or 'off'
  vim.api.nvim_echo(
    {{ 'spell check: ' .. state, 'WarningMsg' }}, false, {}
  )
end)

-- preserve the " register when pasting over a visual selection
vim.keymap.set('x', 'p', 'P')

-- toggle quickfix/location lists
vim.keymap.set('n', '<leader>ct', function()
  vim.cmd(vim.o.ft == 'qf' and 'cclose' or 'copen')
end)
vim.keymap.set('n', '<leader>lt', function()
  local list = vim.fn.getloclist(0)
  if #list == 0 then
    vim.api.nvim_echo({{ 'no location list', 'WarningMsg' }}, false, {})
    return
  end
  vim.cmd(vim.o.ft == 'qf' and 'lclose' or 'lopen')
end)

-- write and go to next quickfix/location list result
vim.keymap.set('n', '<leader>cn', function() _next_error('c', 'cnext') end)
vim.keymap.set('n', '<leader>cf', function() _next_error('c', 'cnfile') end)
vim.keymap.set('n', '<leader>ln', function() _next_error('l', 'lnext') end)
function _next_error(list, cmd) ---@diagnostic disable-line: lowercase-global {{{
  local func = list  == 'c' and
    function(...) return vim.fn.getqflist(...) end or
    function(...) return vim.fn.getloclist(0, ...) end
  local error_count = #func()
  if error_count == 0 then
    vim.api.nvim_echo({{ 'no entries', 'WarningMsg' }}, false, {})
    return
  end

  -- write the file if necessary
  vim.cmd('noautocmd silent update')

  -- check new error count to handle case where writing the file modifies the
  -- results.
  local updated_error_count = #func()
  if updated_error_count ~= error_count then
     -- cc or ll (return to the current error position)
    cmd = list .. list
  end
  local current = func({ idx = 0 })['idx']
  if current == updated_error_count then
    vim.api.nvim_echo({{ 'no more entries', 'WarningMsg' }}, false, {})
    return
  end
  vim.cmd(cmd)
end -- }}}

-- open the quickfix/location list and jump to the first entry for the line
-- under the cursor
vim.keymap.set('n', '<leader>cc', function() _current_error('c') end)
vim.keymap.set('n', '<leader>ll', function() _current_error('l') end)
function _current_error(list) ---@diagnostic disable-line: lowercase-global {{{
  local pos = vim.fn.getcurpos()
  local lnum = vim.fn.line('.')
  local open = list .. 'open'
  vim.cmd(open)
  vim.fn.cursor(1, 1)

  local found = vim.fn.search('|' .. pos[2] .. '\\>')
  if found then
    vim.cmd(vim.fn.line('.') .. list .. list)
    vim.fn.cursor(lnum, pos[2])
    vim.cmd(open)
  else
    vim.api.nvim_echo(
      {{ 'no entry found for line ' .. lnum, 'WarningMsg' }}, false, {}
    )
  end
end -- }}}

-- virtualedit mappings to start insert no farther than the end of the actual
-- line
vim.keymap.set('n', 'a', function() return _virtual_edit('a') end, { expr = true })
vim.keymap.set('n', 'i', function() return _virtual_edit('i') end, { expr = true })
function _virtual_edit(key) ---@diagnostic disable-line: lowercase-global {{{
  -- when starting insert on an empty line, start it at the correct indent
  if #vim.fn.getline('.') == 0 and vim.fn.line('$') ~= 1 then
    return vim.fn.line('.') == vim.fn.line('$') and 'ddo' or 'ddO'
  end
  return (vim.fn.virtcol('.') > vim.fn.col('$') and '$' or '') .. key
end -- }}}

-- swap 2 words
vim.keymap.set('n', '<leader>ws', function()
  local pos = vim.fn.getpos('.')
  vim.cmd('normal! "_yiw')
  vim.cmd('keepp keepj s/\\(\\%#\\w\\+\\)\\(\\_W\\+\\)\\(\\w\\+\\)/\\3\\2\\1/')
  vim.fn.setpos('.', pos)
end)

-- }}}

-- commands {{{

-- Tab (open a new tab using the supplied working directory) {{{
-- command! -nargs=1 -complete=dir Tab :call <SID>Tab('<args>')
vim.api.nvim_create_user_command('Tab', function(opts)
  local dir = opts.args
  if vim.fn.isdirectory(dir) == 0 then
    vim.api.nvim_echo({{ 'Not found: ' .. dir, 'Error' }}, false, {})
    return
  end

  dir = vim.fn.fnamemodify(dir, ':p')
  if dir:match('/$') then
    dir = string.sub(dir, 1, -2)
  end

  -- if the current tab isn't already named, has no modifications, no
  -- additional windows, and only an empty [No Name] buffer, then skip opening
  -- a new tab and just name this one.
  if vim.o.modified or
     vim.fn.exists('t:tab_name') ~= 0 or
     vim.fn.winnr('$') > 1 or
     vim.fn.expand('%') ~= '' or
     vim.fn.line('$') ~= 1 or
     vim.fn.getline(1) ~= '' then
    vim.cmd('tablast | tabnew')
  end
  vim.api.nvim_tabpage_set_var(0, 'tab_name', vim.fn.fnamemodify(dir, ':t'))
  vim.cmd('tcd ' .. vim.fn.escape(dir, ' '))

  vim.o.showtabline = 2

  vim.api.nvim_create_augroup('Tab', {})
  vim.api.nvim_create_autocmd('TabEnter', {
    group = 'Tab',
    pattern = '*',
    callback = function()
      if vim.fn.tabpagenr('$') == 1 and vim.fn.exists('t:tab_name') == 0 then
        vim.o.showtabline = 1
      end
    end
  })
end, { nargs = 1, complete = 'dir' }) -- }}}

-- Mergetool (mergetool for git) {{{
-- .gitconfig
--   [merge]
--     tool = nvim
--   [mergetool "nvim"]
--     cmd = nvim -d -O3 "$LOCAL" "$BASE" "$REMOTE" "$MERGED" -c "Mergetool"
---@diagnostic disable-next-line: unused-local
vim.api.nvim_create_user_command('Mergetool', function(opts)
  if vim.fn.bufnr('$') ~= 4 then
    vim.api.nvim_echo(
      {{ 'Unexpected number of buffers: ' .. vim.fn.bufnr('$'), 'Error' }},
      true,
      {}
    )
    return
  end

  if vim.fn.winnr('$') ~= 3 then
    vim.api.nvim_echo(
      {{ 'Unexpected number of windows: ' .. vim.fn.winnr('$'), 'Error' }},
      true,
      {}
    )
    return
  end

  -- relies on repo alias from my .gitconfg
  local branch = vim.fn.split(vim.fn.systemlist('git repo')[1], ':')[2]
  local files = {
    REMOTE = 'MERGING IN',
    BASE = 'COMMON BASE',
    LOCAL = 'CURRENT BRANCH',
  }
  if branch == 'rebase' then
    -- with a rebase the current branch becomes the REMOTE since it is applied
    -- last, and the LOCAL is the other branch that we are attempting to rebase
    -- on top of.
    files = {
      REMOTE = 'CURRENT BRANCH',
      BASE = 'COMMON BASE',
      LOCAL = 'REBASE ONTO',
    }
  end

  for name, display in pairs(files) do
    local pattern = '*_' .. name .. '_*'
    local winnr = vim.fn.bufwinnr(pattern)
    if winnr == -1 then
      vim.api.nvim_echo(
        {{ 'Missing expected file: ' .. pattern, 'Error' }},
        false,
        {}
      )
      return
    end
    vim.cmd(winnr .. 'winc w')
    vim.wo.statusline = display
  end

  local merge = vim.fn.bufname(4)
  vim.cmd('bot diffsplit ' .. merge)
end, { nargs = 0 }) -- }}}

-- }}}

-- abbreviations {{{

vim.keymap.set('ca', 'ln', 'lnext')

-- }}}

-- autocmds {{{

-- when editing a file, jump to the last known cursor position.
vim.api.nvim_create_autocmd('BufReadPost', {
  pattern = '*',
  callback = function()
    -- wrapped since nvim may throw an error
    pcall(vim.cmd('silent normal! g`"'))
  end
})

-- disallow writing to read only files
-- autocmd BufNewFile,BufRead * :let &modifiable = !&readonly
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  pattern = '*',
  callback = function() vim.o.modifiable = not vim.o.readonly end
})

-- only highlight cursor line of the current window, making is easier to
-- pick out which window has focus
vim.api.nvim_create_autocmd('WinLeave', {
  pattern = '*',
  callback = function() vim.o.cursorline = false end
})
vim.api.nvim_create_autocmd({ 'VimEnter', 'WinEnter', 'FileType' }, {
  pattern = '*',
  callback = function() vim.o.cursorline = vim.o.ft ~= 'qf' end
})

-- }}}

-- plugins (via lazy.nvim) {{{

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
vim.opt.rtp:prepend(lazypath)

require('lazy').setup(
  'plugins',  -- load plugins from .config/nvim/lua/plugins
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
local loaded, err = pcall(function() require('work') end)
if not loaded and err ~= nil and not err:match("module 'work' not found") then
  vim.schedule(function()
    vim.api.nvim_echo({{ err, 'Error' }}, true, {})
  end)
end

-- vim:fdm=marker
