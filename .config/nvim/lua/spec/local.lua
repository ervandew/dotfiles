-- local plugins
return {
  {
    dir = '~/.vim/',
    config = function()
      -- diff
      vim.keymap.set('ca', 'dn', 'DiffNextChange')
      vim.keymap.set('ca', 'dp', 'DiffPrevChange')

      -- indentdetect
      vim.api.nvim_create_autocmd('FileType', {
        pattern = '*',
        callback = function()
          if vim.fn.exists(':IndentDetect') == 2 then
            vim.cmd.IndentDetect()
          end
        end
      })

      -- ranger
      vim.keymap.set('n', '<leader>/', ':Ranger<cr>', { silent = true })
    end
  },
  {dir = '~/.vim/bundle/eclim'},
}
