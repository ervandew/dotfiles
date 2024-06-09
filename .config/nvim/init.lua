-- use vim settings in neovim
vim.opt.rtp:prepend('~/.vim/')
vim.cmd([[
let &packpath = &runtimepath
source ~/.vimrc
]])

-- neovim options {{{
vim.opt.inccommand = 'split' -- preview changes in a separate window
vim.opt.termguicolors = true -- use full set of gui colors
-- }}}

-- neovim plugins (via lazy.nvim) {{{

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup(
  'plugins',  -- load plugins from .config/nvim/lua/plugins
  {           -- lazy.nvim config options
    change_detection = {
      enable = false,
      notify = false,
    },
    ui = { border = 'rounded' },
  }
)

-- }}}

-- vim:fdm=marker
