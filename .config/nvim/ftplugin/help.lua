vim.keymap.set('n', '<cr>', function()
  local link = vim.treesitter.get_node():parent():type() == 'taglink'
  if link then
    vim.fn.feedkeys(
      vim.api.nvim_replace_termcodes('<c-]>', true, false, true),
      'nt'
    )
  end
end, { buffer = true })
