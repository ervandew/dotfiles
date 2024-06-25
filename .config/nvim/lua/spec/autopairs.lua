return {{
  'windwp/nvim-autopairs',
  event = 'InsertEnter',
  config = function()
    local autopairs = require('nvim-autopairs')
    local cond = require('nvim-autopairs.conds')
    local default = require('nvim-autopairs.rules.basic')
    local Rule = require('nvim-autopairs.rule')
    autopairs.setup({
      -- don't split pair matching into their undo
      break_undo = false,
      -- don't use treesitter, prevents adding a quote before another quoted
      -- string
      check_ts = false,
      -- prevent case where sometimes typing a closing bracket will add a new
      -- one instead of overwriting the one that was auto inserted
      -- Note: this just prevents the default
      -- :with_pair(cond.is_bracket_line()) call since we manually add
      -- cond.is_bracket_line_move() to the bracket rules below.
      enable_check_bracket_line = false,
      -- don't auto add pair if the next isn't in the following negated set
      ignored_next_char = '[^,:\'"%s}%)%]]',
    })

    -- start with default rules when overriding for file type specific pairs
    local quote = default.quote_creator(autopairs.config)
    local bracket = default.bracket_creator(autopairs.config)

    -- block_wrap (attempt to suppress closing bracket when wrapping a block {{{
    local block_wrap = function(opts) ---@diagnostic disable-line: unused-local
      local trailing = string.sub(opts.line, opts.col, -1)
      if trailing:match('^%s*$') then
        local next_line = vim.fn.getline(vim.fn.line('.') + 1)
        -- if the next line ends in a comma, then we are probably wrapping a
        -- block to create list, tuple, or dict
        if next_line:match(',$') then
          return false
        end
      end
    end

    local bracket_ignored_next_char = '[\'"]'
    autopairs.get_rules('(')[1]
      :with_pair(block_wrap)
      :with_pair(cond.not_after_regex(bracket_ignored_next_char))
      :with_move(cond.is_bracket_line_move())
    autopairs.get_rules('{')[1]
      :with_pair(block_wrap)
      :with_pair(cond.not_after_regex(bracket_ignored_next_char))
      :with_move(cond.is_bracket_line_move())
    autopairs.get_rules('[')[1]
      :with_pair(block_wrap)
      :with_pair(cond.not_after_regex(bracket_ignored_next_char))
      :with_move(cond.is_bracket_line_move())
    -- }}}

    -- not_after_regex {{{
    -- autopairs version doesn't use the whole line, but having the whole line
    -- to match against is much more flexible
    local not_after_regex = function(regex)
      return function(opts)
        if opts.line:match(regex) then
          return false
        end
      end
    end -- }}}

    -- closetag (returns a rule to close a tag) {{{
    --   closing string (>, %}, ...)
    --   template for the closing tag where %s is replaced with the tag name
    --   pattern used to find the tag name from the current line
    --   string or table of the file type to target
    local closetag = function(...)
      local params = {...}
      local matched = function(opts)
        -- only execute at the end of line
        local suffix = opts.line:sub(opts.col + 1)
        if suffix:match('^%s*$') == nil then
          return false
        end

        -- only execute if we found the tag name
        local tag = string.gsub(opts.line, params[3], '%1')
        if tag == opts.line then
          return false
        end
      end

      -- find the start tag to grab the name to put into the end pair
      local close = function(opts)
        local tag = string.gsub(opts.line, params[3], '%1')
        return string.gsub(opts.rule.end_pair, '%%s', tag)
      end

      return Rule(params[1], params[2], params[4])
        :end_wise(matched)
        :replace_endpair(close)
    end -- }}}

    -- htmljinja {{{
    -- disable { rule
    autopairs.get_rules('{')[1]:with_pair(cond.not_filetypes({ 'htmljinja' }))
    -- create {{ rule
    autopairs.add_rule(Rule('{{', '}}', 'htmljinja'))

    -- auto close html tags
    autopairs.add_rule(closetag('>', '</%s>', '.*<%s*(%a+).*', 'htmljinja'))
    -- auto close jinja tags
    autopairs.add_rule(closetag(
      '%}',
      '{% end%s %}',
      '.*{%%%-?%s*(%a*).*%-?%%}',
      'htmljinja'
    ))

    -- }}}

    -- lua {{{
    -- disable default {, replace with version that won't trigger in a comment
    -- (for folding)
    autopairs.get_rules('{')[1]
      :with_move(cond.not_filetypes({ 'lua' }))
      :with_pair(cond.not_filetypes({ 'lua' }))
    autopairs.add_rule(bracket('{', '}', 'lua')
      :with_pair(block_wrap)
      :with_pair(not_after_regex('%s*%-%-'))
      :with_pair(cond.not_after_regex(bracket_ignored_next_char))
      :with_move(cond.is_bracket_line_move())
    )

    -- auto close various statements
    autopairs.add_rules({
      Rule('then', 'end', 'lua')
        :end_wise(function(opts)
          return string.match(opts.line, '^%s*if%W.*then%s*$') ~= nil
        end),
      Rule('do', 'end', 'lua')
        :end_wise(function(opts)
          local match = string.gsub(opts.line, '^%s*(%w+)%W.*do%s*$', '%1')
          return match == 'for' or match == 'while'
        end),
      Rule(')', 'end', 'lua')
        :end_wise(function(opts)
          return string.match(opts.line, '%W*function%s*%([^%)]*%)[%s%)}]*$') ~= nil
        end),
    })
    -- }}}

    -- vim {{{
    -- disable default ", replace with version that won't trigger at the start
    -- of a comment
    autopairs.get_rules('"')[1]
      :with_move(cond.not_filetypes({ 'vim' }))
      :with_pair(cond.not_filetypes({ 'vim' }))
    autopairs.add_rule(quote('"', '"', { 'vim' })
      :with_pair(block_wrap)
      :with_pair(not_after_regex('^%s*'))
      :with_pair(cond.not_after_regex(bracket_ignored_next_char))
      :with_move(cond.is_bracket_line_move())
    )
    -- disable default {, replace with version that won't trigger in a comment
    -- (for folding)
    autopairs.get_rules('{')[1]:with_pair(cond.not_filetypes({ 'vim' }))
    autopairs.add_rule(bracket('{', '}', 'vim')
      :with_pair(not_after_regex('^%s*"'))
    )

    -- auto close various statements
    autopairs.add_rules({
      Rule('.', 'end', 'vim')
        :use_regex(true)
        :end_wise(function(opts)
          local keywords = { 'if', 'for', 'while', 'try', 'function' }
          for _, keyword in ipairs(keywords) do
            if string.match(opts.line, '^%s*' .. keyword .. '%W') ~= nil then
              return true
            end
          end
          return false
        end)
        :replace_endpair(function(opts)
          return 'end' .. string.gsub(opts.line, '^%s*(%w+).*', '%1')
        end),
    })
    -- }}}

  end
}}

-- vim:fdm=marker
