-- options {{{
vim.opt.guicursor = (
  'n-c-sm:block-TermCursor,' ..
  'i-ci-ve:ver25-TermCursor,' ..
  'r-cr-o:hor20-TermCursor,v:block-VisualCursor'
)
vim.opt.clipboard = 'unnamed'
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
vim.opt.shiftwidth = 2
vim.opt.sidescrolloff = 10
vim.opt.signcolumn = 'number'
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.switchbuf = 'useopen'
vim.opt.tabstop = 2
vim.opt.timeoutlen = 500
vim.opt.updatetime = 1000
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
vim.opt.statusline = '%<%{%v:lua._status()%} %h%r%=%-10.(%l,%c%V b=%n,w=%{winnr()}%) %P'
local severities = {
  [vim.diagnostic.severity.ERROR] = 'DiagnosticStatusError',
  [vim.diagnostic.severity.WARN] = 'DiagnosticStatusWarn',
  [vim.diagnostic.severity.INFO] = 'DiagnosticStatusInfo',
  [vim.diagnostic.severity.HINT] = 'DiagnosticStatusHint',
}
function _status() ---@diagnostic disable-line: lowercase-global
  local name = vim.fn.bufname()
  if name == '' then
    name = '[No Name]'
  end
  local stl = name .. (vim.o.modified and ' +' or '')
  local curwin = vim.fn.str2nr(vim.g.actual_curwin)
  local winid = vim.fn.win_getid()
  if curwin == winid then
    -- show the max diagnostic severity in the statusline
    if vim.b.diagnostic ~= nil then
      local hi = severities[vim.b.diagnostic.severity]
      stl = '%#' .. hi .. '#' .. stl .. '%*'
    end
  end

  local stl_addl = ''
  -- show the quickfix title
  if vim.o.ft == 'qf' then
    stl_addl = vim.fn.getqflist({ title = true })
  -- for csv files, display which column the cursor is in
  elseif vim.o.ft == 'csv' then
    if vim.fn.exists(':CSV_WCol') == 3 then
      stl_addl = '[col: ' .. vim.fn.CSV_WCol('Name') .. ' (' .. vim.fn.CSV_WCol() .. ')]'
    end
  end

  -- show in the status line if the file is in dos format
  if vim.o.ff ~= 'unix' then
    stl_addl = '[' .. vim.o.ff .. '] ' .. stl_addl
  end

  if curwin == winid then
    stl_addl = '%#StatusLineFF#' .. stl_addl .. '%*'
  end

  return stl .. ' ' .. stl_addl
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
          if #lines > 0 then
            local branch = lines[1]:gsub('ref: refs/heads/', '')
            if branch ~= '' and branch ~= lines[1] then
              tab_name = tab_name .. '(' .. branch .. ')'
            end
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

-- modified version of '*' which doesn't move the cursor
vim.keymap.set(
  'n',
  '*',
  '"syiw<esc>: let @/ = "\\\\<" . @s . "\\\\>"<cr>:set hls<cr>',
  { silent = true }
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

-- swap 2 words
vim.keymap.set('n', '<leader>ws', function()
  local pos = vim.fn.getpos('.')
  vim.cmd('normal! "_yiw')
  vim.cmd('keepp keepj s/\\(\\%#\\w\\+\\)\\(\\_W\\+\\)\\(\\w\\+\\)/\\3\\2\\1/')
  vim.fn.setpos('.', pos)
end)

vim.keymap.set('n', 'gf', ':Grep --files<cr>', { silent = true })
vim.keymap.set('n', 'gF', ':Grep! --files<cr>', { silent = true })

require('qf').mappings()
require('virtualedit').mappings()

vim.keymap.set('n', '<space><space>', function()
  require('maximize').toggle()
end)

vim.keymap.set('n', '<leader>b', function()
  require('buffers').toggle()
end)
-- }}}

-- commands {{{

vim.api.nvim_create_user_command('BufferDelete', function()
  require('buffers').delete()
end, { nargs = 0 })

vim.api.nvim_create_user_command(
  'Grep',
  function(opts) require('grep').find(opts) end,
  {
    bang = true,
    nargs = '*',
    complete = function(...) return require('grep').complete(...) end,
  }
)

vim.api.nvim_create_user_command('Tab', function(opts)
  require('tab').open(opts)
end, { nargs = 1, complete = 'dir' })

vim.api.nvim_create_user_command('Wrap', function()
  require('wrap').eval()
end, { nargs = 0 })

vim.api.nvim_create_user_command('Mergetool', function()
  require('mergetool').setup()
end, { nargs = 0 })

-- }}}

-- abbreviations {{{

vim.keymap.set('ca', 'bd', 'BufferDelete')
vim.keymap.set('ca', 'ln', 'lnext')
vim.keymap.set('ca', 'gr', 'Grep')
vim.keymap.set('ca', 'rg', 'Grep')

-- }}}

-- autocmds {{{

-- when editing a file, jump to the last known cursor position.
vim.api.nvim_create_autocmd('BufReadPost', {
  pattern = '*',
  callback = function()
    if vim.fn.bufname():match('/%.git/') ~= nil then return end
    vim.cmd('silent! normal! g`"zz')
  end
})

-- disallow writing to read only files
-- autocmd BufNewFile,BufRead * :let &modifiable = !&readonly
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  pattern = '*',
  callback = function() vim.bo.modifiable = not vim.bo.readonly end
})

-- only highlight cursor line / color column of the current window, making is
-- easier to pick out which window has focus
vim.api.nvim_create_autocmd('WinLeave', {
  pattern = '*',
  callback = function()
    vim.o.cursorline = false
    vim.o.colorcolumn = ''
  end
})
vim.api.nvim_create_autocmd({ 'VimEnter', 'WinEnter', 'FileType' }, {
  pattern = '*',
  callback = function()
    -- don't show the colorcolumn for certain file types or files that can't be
    -- edited
    local ignore = { 'man', 'qf' }
    if not vim.list_contains(ignore, vim.o.ft) and not vim.o.readonly then
      vim.opt.colorcolumn = '82'
    end
    vim.o.cursorline = true
  end
})

-- allow opening a file at a line number: foo/bar.txt:12
vim.api.nvim_create_autocmd('BufReadCmd', {
  pattern = '*:*',
  callback = function(args)
    local path, line = unpack(vim.fn.split(args.match, ':'))
    if vim.fn.filereadable(path) == 1 then
      vim.cmd('bwipeout!')
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
    end
  end
})

require('buffers').tab_tracking()
require('indentdetect').autocmd()
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
local loaded, err = pcall(function() require('work') end)
if not loaded and err ~= nil and not err:match("module 'work' not found") then
  vim.schedule(function()
    vim.api.nvim_echo({{ err, 'Error' }}, true, {})
  end)
end

-- vim:fdm=marker
