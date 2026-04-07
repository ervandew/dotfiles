-- NOTE: check that all dependencies are met, etc
-- :checkhealth nvim-treesitter
return {{
  'nvim-treesitter/nvim-treesitter',
  branch = 'main', -- stable
  build = ':TSUpdate',
  lazy = false,
  config = function()
    require('nvim-treesitter').setup({})
  end,
  init = function()
   local ensure_installed = {
      'bash',
      'comment', -- to highlight FIXME, TODO, etc.
      'javascript',
      'lua',
      'query',
      'python',
      'rst',
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
  end
}}
