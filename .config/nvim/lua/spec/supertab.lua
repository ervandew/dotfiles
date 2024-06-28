return {{
  'ervandew/supertab',
  dir = '~/projects/vim/supertab',
  init = function()
    vim.g.SuperTabDefaultCompletionType = 'context'
    vim.g.SuperTabContextTextFileTypeExclusions = {'javascript', 'sql'}
    vim.g.SuperTabLongestEnhanced = 1
    vim.g.SuperTabClosePreviewOnPopupClose = 1
  end,
  config = function()
    -- map <c-space> to <c-p> completion (useful when supertab 'context'
    -- defaults to something else).
    vim.keymap.set('i', '<c-space>', '<c-r>=SuperTabAlternateCompletion("\\<lt>c-p>")<cr>')

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'python',
      callback = function()
        if vim.o.completefunc ~= '' then
          vim.fn.SuperTabChain(vim.o.completefunc, "<c-p>")
        end
      end
    })
  end,
}}

-- vim:fdm=marker
