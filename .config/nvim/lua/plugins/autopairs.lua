return {{
  'windwp/nvim-autopairs',
  event = 'InsertEnter',
  config = function()
    local autopairs = require('nvim-autopairs')
    local cond = require('nvim-autopairs.conds')
    local Rule = require('nvim-autopairs.rule')
    autopairs.setup({
      check_ts = true,
      map_cr = true,
    })

    -- not_after_regex {{{
    -- autopairs version doesn't use the whole line, but having the whole line
    -- to match against is much more flexible
    not_after_regex = function(regex)
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
    closetag = function(...)
      local params = {...}

      matched = function(opts)
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
      close = function(opts)
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
    autopairs.get_rules('{')[1]:with_pair(cond.not_filetypes({ 'lua' }))
    autopairs.add_rule(Rule('{', '}', 'lua')
      :with_pair(not_after_regex('^%s*%-%-'))
    )

    -- auto close various statements
    autopairs.add_rules({
      Rule('then', 'end', 'lua')
        :end_wise(function(opts)
          return string.match(opts.line, '^%s*if%W') ~= nil
        end),
      Rule('do', 'end', 'lua')
        :end_wise(function(opts)
          local match = string.gsub(opts.line, '^%s*(%w+)%W.*', '%1')
          return match == 'for' or match == 'while'
        end),
      Rule(')', 'end', 'lua')
        :end_wise(function(opts)
          return string.match(opts.line, '%W*function%W') ~= nil
        end),
    })
    -- }}}

    -- vim {{{
    -- disable default ", replace with version that won't trigger at the start
    -- of a comment
    autopairs.get_rules('"')[1]:with_pair(cond.not_filetypes({ 'vim' }))
    autopairs.add_rule(Rule('"', '"', { 'vim' })
      :with_pair(not_after_regex('^%s*'))
    )
    -- disable default {, replace with version that won't trigger in a comment
    -- (for folding)
    autopairs.get_rules('{')[1]:with_pair(cond.not_filetypes({ 'vim' }))
    autopairs.add_rule(Rule('{', '}', 'vim')
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
