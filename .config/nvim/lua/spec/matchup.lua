return {{
  'andymass/vim-matchup',
  config = function()
    vim.g.matchup_matchparen_deferred = true
    vim.g.matchup_matchparen_hi_surround_always = true
    -- disabled, usse nvim-treesitter-context instead
    vim.g.matchup_matchparen_offscreen = {}

    -- effectively switch from using a CursorMoved autocmd to CursorHold
    -- since CursorMoved can result in cpu spikes, bit of lag, etc, even with
    -- the matchparen deferred setting enabled.
    vim.cmd('autocmd! matchup_matchparen CursorMoved,CursorMovedI')
    vim.cmd(
      'autocmd matchup_matchparen CursorHold * ' ..
      'doautocmd matchup_matchparen TextChanged'
    )
  end,
  init = function()

    -- csv (disable) {{{
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'csv',
      callback = function()
        vim.b.matchup_matchparen_enabled = 0
      end,
    }) -- }}}

    -- htmljinja {{{
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'htmljinja',
      callback = function()
        vim.b.match_words = table.concat({
          '<!--:-->',
          '<:>',
          '<\\@<=[ou]l\\>[^>]*\\%(>\\|$\\):<\\@<=li\\>:<\\@<=/[ou]l>',
          '<\\@<=dl\\>[^>]*\\%(>\\|$\\):<\\@<=d[td]\\>:<\\@<=/dl>',
          '<\\@<=\\([^/!][^ \\t>]*\\)[^>]*\\%(>\\|$\\):<\\@<=/\\1>',
          '{%-\\?\\s*\\<block\\>:{%-\\?\\s*\\<endblock\\>\\s*-\\?%}',
          '{%-\\?\\s*\\<call\\>:{%-\\?\\s*\\<endcall\\>\\s*-\\?%}',
          '{%-\\?\\s*\\<filter\\>:{%-\\?\\s*\\<endfilter\\>\\s*-\\?%}',
          '{%-\\?\\s*\\<for\\>:{%-\\?\\s*\\<endfor\\>\\s*-\\?%}',
          '{%-\\?\\s*\\<if\\>:{%-\\?\\s*\\<elif\\>:{%-\\?\\s*\\<else\\>:{%-\\?\\s*\\<endif\\>\\s*-\\?%}',
          '{%-\\?\\s*\\<macro\\>:{%-\\?\\s*\\<endmacro\\>\\s*-\\?%}',
        }, ',')
      end
    }) -- }}}

  end,
}}

-- vim:fdm=marker
