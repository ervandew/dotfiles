return {{
  'andymass/vim-matchup',
  config = function()
    vim.g.matchup_matchparen_deferred = true
    vim.g.matchup_matchparen_hi_surround_always = true
    -- disabled, usse nvim-treesitter-context instead
    vim.g.matchup_matchparen_offscreen = {}
  end,
}}
