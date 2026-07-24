---@type vim.lsp.Config

vim.api.nvim_create_user_command('Ty', function(opts)
  vim.bo.makeprg = 'ty check --output-format concise'
  vim.cmd.make(opts.args)
  vim.cmd.copen()
  vim.cmd.cfirst()
end, { complete = 'file', nargs = '*' })

vim.keymap.set('ca', 'ty', function()
  local abbrev = 'ty'
  local type = vim.fn.getcmdtype()
  local pos = vim.fn.getcmdpos()
  local cmdl = vim.fn.getcmdline():sub(1, pos)
  ---@diagnostic disable-next-line: param-type-mismatch
  local char = vim.fn.nr2char(vim.fn.getchar(1))
  if type == ':' and char:match('[%!%s\r]') and cmdl == abbrev then
    return 'Ty'
  end
  return abbrev
end, { expr = true })

return {
  cmd = { 'ty', 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'requirements.txt', '.git' },
}
