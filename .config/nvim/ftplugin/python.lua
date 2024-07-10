-- prevent nvim/runtime/ftplugin/python.vim from settings shiftwidth, etc.
vim.g.python_recommended_style = 0

vim.api.nvim_buf_create_user_command(0, 'FormatStack', function(opts)
  local pos = vim.fn.getpos('.')
  local line1 = opts.line1
  local line2 = opts.line2
  vim.cmd(
    'silent ' .. line1 .. ',' .. line2 ..
    's/\\([^\\n]\\)\\s\\+\\(File ".\\{-}",\\)/\\1\r    \\2/g'
  )
  line2 = vim.fn.line('.')
  vim.cmd(
    'silent ' .. line1 .. ',' .. line2 ..
    's/\\(File ".\\{-}", line \\d\\+, in [^ ]\\+\\)\\s\\+/\\1\r        /'
  )
  line2 = vim.fn.line('.')
  vim.cmd(
    'silent ' .. line1 .. ',' .. line2 ..
    's/\\s\\+\\(\\^\\+\\)/\r        \\1/'
  )
  vim.cmd('silent ' .. 's/^\\(\\s\\+\\^\\+\\)/\\1\r/')
  vim.cmd('nohl')
  vim.fn.setpos('.', pos)
end, { nargs = 0, range = '%' })
