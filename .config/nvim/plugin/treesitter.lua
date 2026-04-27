-- NOTE: check that all dependencies are met, etc
-- :checkhealth nvim-treesitter
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(event)
    if event.data.spec.name == 'nvim-treesitter' and
       event.data.kind == 'update'
    then
      -- ensure nvim-treesitter is loaded before calling TSUpdate
      if not event.data.active then
        vim.cmd.packadd('nvim-treesitter')
      end
      vim.cmd('TSUpdate')
    end
  end
})

vim.pack.add({
  {
    src = 'https://github.com/nvim-treesitter/nvim-treesitter',
    version = 'main',
  }
})

require('nvim-treesitter').setup({})
local ensure_installed = {
  'bash',
  'comment', -- to highlight FIXME, TODO, etc.
  'javascript',
  'lua',
  'query',
  'python',
  'rst',
  'sql',
  'vim',
  'vimdoc',
}
local installed = require('nvim-treesitter.config').get_installed()
local to_install = vim.iter(ensure_installed)
  :filter(function(parser)
    return not vim.tbl_contains(installed, parser)
  end)
  :totable()
require('nvim-treesitter').install(to_install)

vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    -- auto install missing parsers
    local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
    local is_installed = pcall(vim.treesitter.language.add, lang)
    if not is_installed then
       vim.schedule(function() vim.cmd('TSInstall ' .. lang) end)
    end

    -- enable treesitter highlighting
    pcall(vim.treesitter.start)

    -- enable treesitter-based indentation
    -- vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
