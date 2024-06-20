return {{
  'andymass/vim-matchup',
  config = function()
    vim.g.matchup_matchparen_offscreen = {
      method = 'popup',
      -- custom highlight, must be defined by colorscheme/autocmd
      highlight = 'MatchParenOffscreen',
    }
    vim.g.matchup_matchparen_deferred = true
    vim.g.matchup_matchparen_hi_surround_always = true
  end,
}}
