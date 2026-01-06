return {{
  'andymass/vim-matchup',
  config = function()
    vim.g.matchup_matchparen_deferred = true
    vim.g.matchup_matchparen_hi_surround_always = true
    -- disabled, usse nvim-treesitter-context instead
    vim.g.matchup_matchparen_offscreen = {}
    -- don't show the trailing virtual text at the end of code blocks
    vim.g.matchup_treesitter_disable_virtual_text = true

    -- replace CursorMoved*, Insert*, and TextChanged* autocmds with a
    -- CursorHold since a file with large blocks can cause matchup to be really
    -- slow and interfere with typing
    vim.cmd(
      'autocmd! matchup_matchparen ' ..
        'CursorMoved,' ..
        'CursorMovedI,' ..
        'InsertChange,' ..
        'InsertEnter,' ..
        'InsertLeave,' ..
        'TextChanged,' ..
        'TextChangedI,' ..
        'TextChangedP'
    )
    vim.api.nvim_create_autocmd('CursorHold', {
      group = 'matchup_matchparen',
      callback = function()
        -- CursorHold should only fire in normal mode, but this is firing in
        -- all modes for some reason (nvim bug?), so explicilty limit it to
        -- normal mode
        if vim.fn.mode() == 'n' then
          -- using pcall to prevent matchup errors from grabbing focus
          pcall(vim.cmd.doautocmd, 'matchup_matchparen WinEnter')
        end
      end,
    })

    -- add ability to toggle whether matchup is enabled in the current buffer
    -- (useful for files that cause matchup to take a long time)
    vim.api.nvim_create_user_command('MatchupToggle', function()
      vim.b.matchup_matchparen_enabled = vim.b.matchup_matchparen_enabled == nil and 0 or nil
    end, { nargs = 0 })
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
