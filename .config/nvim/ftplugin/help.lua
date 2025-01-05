vim.keymap.set('n', '<cr>', function()
  local link = vim.treesitter.get_node():parent():type() == 'taglink'
  if link then
    vim.fn.feedkeys(
      vim.api.nvim_replace_termcodes('<c-]>', true, false, true),
      'nt'
    )
  end
end, { buffer = true })

vim.keymap.set('n', 'q', function()
  vim.cmd.quit()
  vim.cmd.doautocmd('WinEnter')
end, { buffer = true })
