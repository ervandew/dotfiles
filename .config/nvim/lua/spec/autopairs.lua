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
        local lnum = vim.fn.line('.')
        local indent_cur = vim.fn.indent(lnum)
        local indent_next = vim.fn.indent(lnum + 1)
        local next_line = vim.fn.getline(lnum + 1)
        -- if the next line is at the same or more of an indent, and ends in a
        -- comma, then we are probably wrapping a block to create list, tuple,
        -- or dict
        if indent_next >= indent_cur and next_line:match(',$') then
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

    -- not_filetype (disables a rule by its key, for the supplied filetype) {{{
    local not_filetype = function(rule_key, ft)
      local rule = autopairs.get_rules(rule_key)[1]
      if rule.not_filetypes == nil then
        rule.not_filetypes = {}
      end
      rule.not_filetypes[#rule.not_filetypes + 1] = ft
    end -- }}}

    -- not_after_regex (disable if the opening is after the supplied regex) {{{
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
    --   table of options (all are optional):
    --   - filetypes: string or table of the file type to target
    --   - translate: function to translate the tag found into the tag
    --     to use
    local closetag = function(...)
      local params = {...}
      local closetag_opts = params[4] or {}
      -- find the start tag to grab the name to put into the end pair
      local close = function(opts)
        if opts.closetag then
          return opts.closetag
        end

        local tag = string.gsub(opts.line, params[3], '%1')
        if closetag_opts.translate then
          tag = closetag_opts.translate(tag)
        end
        return string.gsub(opts.rule.end_pair, '%%s', tag)
      end

      local matched = function(opts)
        -- only execute if we found the tag name
        local tag = string.gsub(opts.line, params[3], '%1')
        if tag == opts.line then
          return false
        end

        -- check if the tag is ignored
        if closetag_opts.ignore and
           vim.list_contains(closetag_opts.ignore, tag)
        then
          return false
        end

        -- check any optional addtional condition
        if closetag_opts.cond and closetag_opts.cond(opts) == false then
          return false
        end

        -- only execute at the end of line
        local suffix = opts.line:sub(opts.col + 1)
        if suffix:match('^%s*$') == nil then
          return false
        end

        -- only close if there is no existing close on the next line, at the
        -- same indent level
        local lnum = vim.fn.line('.')
        local lnum_next = lnum + 1
        local indent_next = vim.fn.indent(lnum_next)
        local indent = vim.fn.indent(lnum)
        local closed = close(opts)

        if indent == indent_next and
           vim.trim(vim.fn.getline(lnum_next)) == closed then
          return false
        end

        opts.closetag = closed
      end

      return Rule(params[1], params[2], closetag_opts.filetypes)
        :end_wise(matched)
        :replace_endpair(close)
    end -- }}}

    -- sgmlclosetag (auto complete while typing a close tag) {{{
    local sgmlclosetag = function()
      local ignore = { 'br', 'input' }
      local extract_tags = function(line)
        local tags = {}
        while string.match(line, '<%w+') do
          local tag = vim.fn.substitute(
            line,
            '.\\{-}<\\([a-zA-Z0-9:_.-]\\+\\).*',
            '\\1',
            ''
          )
          if not string.match(line, '<' .. tag .. '[^>]*/>') and
             not vim.list_contains(ignore, tag)
          then
            tags[#tags + 1] = tag
          end
          line = vim.fn.substitute(
            line,
            '.\\{-}<' .. tag .. '\\(.*\\)',
            '\\1',
            ''
          )
        end
        return tags
      end

      local function get_tag(lnum)
        ---@diagnostic disable-next-line: redundant-parameter
        local pairpos = vim.fn.searchpairpos('<\\w', '', '</\\w', 'bnW')
        if pairpos[1] ~= 0 then
          -- test if tag found is self closing
          local self_close_pattern =
            '\\%' .. pairpos[1] .. 'l\\%' .. pairpos[2] .. 'c\\_[^>]*/>'
          if vim.fn.search(self_close_pattern, 'bcnW') ~= 0 then
            local pos = vim.fn.getpos('.')
            vim.fn.cursor(pairpos[1], pairpos[2])
            local _, result = pcall(get_tag, lnum)
            vim.fn.setpos('.', pos)
            return result
          end

          local line = vim.fn.getline(pairpos[1])
          local pos = vim.fn.getpos('.')
          vim.fn.cursor(pairpos[1], pairpos[2])
          local ok, tags = pcall(extract_tags, line)
          if ok then
            -- place the cursor at the end of the line
            vim.fn.cursor(vim.fn.line('.'), vim.fn.col('$'))
            -- loop over the tags in reverse order
            for i = #tags, 1, -1 do
              local tag = tags[i]
              -- find first non self closing tag searching backwards
              vim.fn.search(
                '<' .. tag .. '\\>\\([^>]\\{-}[^/]\\)\\?>',
                'b',
                vim.fn.line('.')
              )
              -- see if the tag has a matching close tag
              local start_tag = '<' .. tag .. '\\>'
              local end_tag = '</' .. tag .. '\\>'
              ---@diagnostic disable-next-line: redundant-parameter
              local tagpairpos = vim.fn.searchpairpos(start_tag, '', end_tag, 'nW')
              if tagpairpos[1] == 0 or tagpairpos[1] > lnum then
                return tag
              end
            end
            vim.fn.cursor(vim.fn.line('.'), 1)
            return get_tag(lnum)
          end
          vim.fn.setpos('.', pos)
        end
      end

      local function close(opts)
        if opts.sgmlclosetag then
          local tag = opts.sgmlclosetag
          local right = vim.api.nvim_replace_termcodes('<right>', true, false, true)
          vim.fn.feedkeys(string.rep(right, #tag + 1), 'tn')
          return tag .. '>'
        end
        return get_tag(vim.fn.line('.'))
      end

      local function matched(opts)
        local tag = close(opts)
        if not tag then
          return false
        end
        opts.sgmlclosetag = tag
      end

      return Rule('</', '>')
        :with_pair(matched)
        :replace_endpair(close)
    end -- }}}

    -- sgmlendtag (rules to autocomplete end tags) {{{
    -- autoclose a tag when hitting enter after the close of the start tag
    local sgml_autoclose = closetag('>', '</%s>', '.*<%s*(%a+).*', {
      ignore = { 'br', 'input' },
      cond = function(opts)
        -- ignore if the tag is already closed
        if string.match(opts.line, '/>%s*') then
          return false
        end
      end
    })
    autopairs.add_rule(sgml_autoclose)

    local sgml_close = sgmlclosetag()
    autopairs.add_rule(sgml_close)

    local sgmlendtag = function(ft)
      if sgml_autoclose.filetypes == nil then
        sgml_autoclose.filetypes = {}
      end
      sgml_autoclose.filetypes[#sgml_autoclose.filetypes + 1] = ft

      if sgml_close.filetypes == nil then
        sgml_close.filetypes = {}
      end
      sgml_close.filetypes[#sgml_close.filetypes + 1] = ft
    end -- }}}

    -- htmljinja {{{
    -- disable { rule
    not_filetype('{', 'htmljinja')

    -- add htmljinja to sgmlendtag filetypes
    sgmlendtag('htmljinja')

    autopairs.add_rule(Rule('{{', ' }}', 'htmljinja'))
    autopairs.add_rule(Rule('{%', ' %}', 'htmljinja'))

    -- auto close jinja tags
    autopairs.add_rule(closetag(
      '%}',
      '{% end%s %}',
      '.*{%%%-?%s*(%a*).*%-?%%}',
      {
        filetypes = 'htmljinja',
        translate = function(tag)
          return (tag == 'elif' or tag == 'else') and 'if' or tag
        end,
      }
    ))
    -- }}}

    -- lua {{{
    -- disable default {, replace with version that won't trigger in a comment
    -- (for folding)
    not_filetype('{', 'lua')
    autopairs.add_rule(bracket('{', '}', 'lua')
      :with_pair(block_wrap)
      :with_pair(not_after_regex('%s*%-%-'))
      :with_pair(cond.not_after_regex(bracket_ignored_next_char))
      :with_move(cond.is_bracket_line_move())
    )

    local eol = function(opts)
      local suffix = string.sub(opts.line, opts.col + 1, #opts.line)
      return suffix == '' or suffix:match('^%s*$') ~= nil
    end

    -- auto close various statements
    autopairs.add_rules({
      Rule('then', 'end', 'lua')
        :end_wise(function(opts)
          return eol(opts) and opts.line:match('^%s*if%W.*then%s*$') ~= nil
        end),
      Rule('do', 'end', 'lua')
        :end_wise(function(opts)
          local match = string.gsub(opts.line, '^%s*(%w+)%W.*do%s*$', '%1')
          return eol(opts) and (match == 'for' or match == 'while')
        end),
      Rule(')', 'end', 'lua')
        :end_wise(function(opts)
          return opts.line:match('%W*function%s*%w*%s*%([^%)]*%)[%s%)}]*$') ~= nil
        end),
    })
    -- }}}

    -- python {{{
    -- disable default triple quote rules so we can customize them
    not_filetype('"""', 'python')
    not_filetype("'''", 'python')
    autopairs.add_rule(quote("'''", "'''", 'python')
      :with_pair(cond.not_before_regex('%w'))
    )
    autopairs.add_rule(quote('"""', '"""', 'python')
      :with_pair(cond.not_before_regex('%w'))
    )
    -- }}}

    -- vim {{{
    -- disable default ", replace with version that won't trigger at the start
    -- of a comment
    not_filetype('"', 'vim')
    autopairs.add_rule(quote('"', '"', { 'vim' })
      :with_pair(block_wrap)
      :with_pair(not_after_regex('^%s*'))
      :with_pair(cond.not_after_regex(bracket_ignored_next_char))
      :with_move(cond.is_bracket_line_move())
    )
    -- disable default {, replace with version that won't trigger in a comment
    -- (for folding)
    not_filetype('{', 'vim')
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
            if opts.line:match('^%s*' .. keyword .. '%W') ~= nil then
              return eol(opts)
            end
          end
          return false
        end)
        :replace_endpair(function(opts)
          return 'end' .. string.gsub(opts.line, '^%s*(%w+).*', '%1')
        end),
    })
    -- }}}

    vim.keymap.set('i', '<c-l>', function() -- mapping to skip inserted chars {{{
      -- while in insert mode, jump to first space after the cursor or the end
      -- of line (a naive way to jump past inserted end pairs. proper support
      -- would require tracking what's been inserted, which autopairs doesn't
      -- seem to do)
      --
      local col = vim.fn.col('.')
      -- note: breaks repeat :/
      local pos = vim.fn.searchpos('\\s\\|$', 'z', vim.fn.line('.'))

      if pos[2] > col then
        -- if we skipped over any indentkeys, then re-indent the line
        local indentkeys = vim.split(vim.o.indentkeys, ',')
        indentkeys = vim.tbl_filter(function(k)
          if k:find('!') == 1 then
            return false
          end
          if k:find('0') == 1 then
            return false
          end
          if k == 'o' or k == 'O' then
            return false
          end
          return true
        end, indentkeys)
        indentkeys = vim.tbl_map(function(k)
          if k:find('=') == 1 then
            k = k:sub(2)
          end
          return k
        end, indentkeys)

        local skipped = vim.fn.getline('.'):sub(col, pos[2])
        for _, key in ipairs(indentkeys) do
          if skipped:find(key) then
            vim.cmd('silent normal ==')
            if vim.fn.virtcol('.') > #vim.fn.getline('.') + 1 then
              vim.fn.cursor(0, #vim.fn.getline('.') + 1)
            end
            break
          end
        end
      end
    end) -- }}}
  end
}}

-- vim:fdm=marker
