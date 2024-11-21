local M = {}

M.open = function(opts)
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
end

M.init = function()
  vim.api.nvim_create_user_command('Tab', M.open , {
    nargs = 1,
    complete = 'dir',
  })
end

return M
