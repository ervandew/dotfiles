---@type vim.lsp.Config

vim.api.nvim_create_user_command('Ruff', function(opts)
  vim.bo.makeprg = 'ruff check --output-format concise'
  vim.cmd.make(opts.args)
  vim.cmd.copen()
  vim.cmd.cfirst()
end, { complete = 'file', nargs = '*' })

vim.keymap.set('ca', 'ruff', function()
  local abbrev = 'ruff'
  local type = vim.fn.getcmdtype()
  local pos = vim.fn.getcmdpos()
  local cmdl = vim.fn.getcmdline():sub(1, pos)
  ---@diagnostic disable-next-line: param-type-mismatch
  local char = vim.fn.nr2char(vim.fn.getchar(1))
  if type == ':' and char:match('[%!%s\r]') and cmdl == abbrev then
    return 'Ruff'
  end
  return abbrev
end, { expr = true })

return {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', '.git' },
  settings = {},
}
