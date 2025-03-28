---Straight copy of neovim's _coomment.lua, with the following changes:
--- Mod: replaced all 'vim._comment' references with 'comment'
--- Mod: updated get_comment_parts() to add option to trim the left comment
---      string to remove the extra space between the comment operator and the
---      string
--- Mod: added align arg to operator()/toggle_lines() to determine if the left
---      comment operator should be aligned with the existing code or inserted
---      at the very start of the line (no indent). Add 'operator_align()' for
---      use with operatorfunc when align is set.
--- Add: added init function to setup the comment mappings, and just expose
---      that and operator functions.
--- Del: remove textobject function that I don't use.

---@nodoc
---@class comment.Parts
---@field left string Left part of comment
---@field right string Right part of comment

--- Get 'commentstring' at cursor
---@param ref_position integer[]
---@return string
local function get_commentstring(ref_position)
  local buf_cs = vim.bo.commentstring

  local has_ts_parser, ts_parser = pcall(vim.treesitter.get_parser)
  if not has_ts_parser then
    return buf_cs
  end

  -- Try to get 'commentstring' associated with local tree-sitter language.
  -- This is useful for injected languages (like markdown with code blocks).
  local row, col = ref_position[1] - 1, ref_position[2]
  local ref_range = { row, col, row, col + 1 }

  -- - Get 'commentstring' from the deepest LanguageTree which both contains
  --   reference range and has valid 'commentstring' (meaning it has at least
  --   one associated 'filetype' with valid 'commentstring').
  --   In simple cases using `parser:language_for_range()` would be enough, but
  --   it fails for languages without valid 'commentstring' (like 'comment').
  local ts_cs, res_level = nil, 0

  ---@param lang_tree vim.treesitter.LanguageTree
  local function traverse(lang_tree, level)
    if not lang_tree:contains(ref_range) then
      return
    end

    local lang = lang_tree:lang()
    local filetypes = vim.treesitter.language.get_filetypes(lang)
    for _, ft in ipairs(filetypes) do
      local cur_cs = vim.filetype.get_option(ft, 'commentstring')
      if cur_cs ~= '' and level > res_level then
        ts_cs = cur_cs
      end
    end

    for _, child_lang_tree in pairs(lang_tree:children()) do
      traverse(child_lang_tree, level + 1)
    end
  end
  traverse(ts_parser, 1)

  return ts_cs or buf_cs
end

--- Compute comment parts from 'commentstring'
---@param ref_position integer[]
---@return comment.Parts
local function get_comment_parts(ref_position, opts)
  local cs = get_commentstring(ref_position)

  if cs == nil or cs == '' then
    vim.api.nvim_echo({ { "Option 'commentstring' is empty.", 'WarningMsg' } }, true, {})
    return { left = '', right = '' }
  end

  if not (type(cs) == 'string' and cs:find('%%s') ~= nil) then
    error(vim.inspect(cs) .. " is not a valid 'commentstring'.")
  end

  -- Structure of 'commentstring': <left part> <%s> <right part>
  local left, right = cs:match('^(.-)%%s(.-)$')
  if opts and opts.trim then
    left = vim.trim(left)
  end
  return { left = left, right = right }
end

--- Make a function that checks if a line is commented
---@param parts comment.Parts
---@return fun(line: string): boolean
local function make_comment_check(parts)
  local l_esc, r_esc = vim.pesc(parts.left), vim.pesc(parts.right)

  -- Commented line has the following structure:
  -- <possible whitespace> <left> <anything> <right> <possible whitespace>
  local nonblank_regex = '^%s-' .. l_esc .. '.*' .. r_esc .. '%s-$'

  -- Commented blank line can have any amount of whitespace around parts
  local blank_regex = '^%s-' .. vim.trim(l_esc) .. '%s*' .. vim.trim(r_esc) .. '%s-$'

  return function(line)
    return line:find(nonblank_regex) ~= nil or line:find(blank_regex) ~= nil
  end
end

--- Compute comment-related information about lines
---@param lines string[]
---@param parts comment.Parts
---@return string indent
---@return boolean is_commented
local function get_lines_info(lines, parts)
  local comment_check = make_comment_check(parts)

  local is_commented = true
  local indent_width = math.huge
  ---@type string
  local indent

  for _, l in ipairs(lines) do
    -- Update lines indent: minimum of all indents except blank lines
    local _, indent_width_cur, indent_cur = l:find('^(%s*)')

    -- Ignore blank lines completely when making a decision
    if indent_width_cur < l:len() then
      -- NOTE: Copying actual indent instead of recreating it with `indent_width`
      -- allows to handle both tabs and spaces
      if indent_width_cur < indent_width then
        ---@diagnostic disable-next-line:cast-local-type
        indent_width, indent = indent_width_cur, indent_cur
      end

      -- Update comment info: commented if every non-blank line is commented
      if is_commented then
        is_commented = comment_check(l)
      end
    end
  end

  -- `indent` can still be `nil` in case all `lines` are empty
  return indent or '', is_commented
end

--- Compute whether a string is blank
---@param x string
---@return boolean is_blank
local function is_blank(x)
  return x:find('^%s*$') ~= nil
end

--- Make a function which comments a line
---@param parts comment.Parts
---@param indent string
---@return fun(line: string): string
local function make_comment_function(parts, indent)
  local prefix, nonindent_start, suffix = indent .. parts.left, indent:len() + 1, parts.right
  local blank_comment = indent .. vim.trim(parts.left) .. vim.trim(parts.right)

  return function(line)
    if is_blank(line) then
      return blank_comment
    end
    return prefix .. line:sub(nonindent_start) .. suffix
  end
end

--- Make a function which uncomments a line
---@param parts comment.Parts
---@return fun(line: string): string
local function make_uncomment_function(parts)
  local l_esc, r_esc = vim.pesc(parts.left), vim.pesc(parts.right)
  local nonblank_regex = '^(%s*)' .. l_esc .. '(.*)' .. r_esc .. '(%s-)$'
  local blank_regex = '^(%s*)' .. vim.trim(l_esc) .. '(%s*)' .. vim.trim(r_esc) .. '(%s-)$'

  return function(line)
    -- Try both non-blank and blank regexes
    local indent, new_line, trail = line:match(nonblank_regex)
    if new_line == nil then
      indent, new_line, trail = line:match(blank_regex)
    end

    -- Return original if line is not commented
    if new_line == nil then
      return line
    end

    -- Prevent trailing whitespace
    if is_blank(new_line) then
      indent, trail = '', ''
    end

    return indent .. new_line .. trail
  end
end

--- Comment/uncomment buffer range
---@param line_start integer
---@param line_end integer
---@param ref_position? integer[]
local function toggle_lines(line_start, line_end, ref_position, opts)
  opts = opts or { align = false, trim = true }
  ref_position = ref_position or { line_start, 0 }
  local parts = get_comment_parts(ref_position, opts)
  local lines = vim.api.nvim_buf_get_lines(0, line_start - 1, line_end, false)
  local indent, is_comment = get_lines_info(lines, parts)

  local f = is_comment and
    make_uncomment_function(parts) or
    make_comment_function(parts, opts.align and indent or '')

  -- Direct `nvim_buf_set_lines()` essentially removes both regular and
  -- extended marks  (squashes to empty range at either side of the region)
  -- inside region. Use 'lockmarks' to preserve regular marks.
  -- Preserving extmarks is not a universally good thing to do:
  -- - Good for non-highlighting in text area extmarks (like showing signs).
  -- - Debatable for highlighting in text area (like LSP semantic tokens).
  --   Mostly because it causes flicker as highlighting is preserved during
  --   comment toggling.
  package.loaded['comment']._lines = vim.tbl_map(f, lines)
  local lua_cmd = string.format(
    'vim.api.nvim_buf_set_lines(0, %d, %d, false, package.loaded["comment"]._lines)',
    line_start - 1,
    line_end
  )
  vim.cmd.lua({ lua_cmd, mods = { lockmarks = true } })
  package.loaded['comment']._lines = nil
end

--- Operator which toggles user-supplied range of lines
---@param mode string?
---|"'line'"
---|"'char'"
---|"'block'"
local function operator(mode, opts)
  opts = opts or { align = false, trim = false }
  -- Used without arguments as part of expression mapping. Otherwise it is
  -- called as 'operatorfunc'.
  if mode == nil then
    if opts.align and opts.trim then
      vim.o.operatorfunc = "v:lua.require'comment'.operator_align_trim"
    elseif opts.align then
      vim.o.operatorfunc = "v:lua.require'comment'.operator_align"
    elseif opts.trim then
      vim.o.operatorfunc = "v:lua.require'comment'.operator_trim"
    else
      vim.o.operatorfunc = "v:lua.require'comment'.operator"
    end
    return 'g@'
  end

  -- Compute target range
  local mark_from, mark_to = "'[", "']"
  local lnum_from, col_from = vim.fn.line(mark_from), vim.fn.col(mark_from)
  local lnum_to, col_to = vim.fn.line(mark_to), vim.fn.col(mark_to)

  -- Do nothing if "from" mark is after "to" (like in empty textobject)
  if (lnum_from > lnum_to) or (lnum_from == lnum_to and col_from > col_to) then
    return
  end

  -- NOTE: use cursor position as reference for possibly computing local
  -- tree-sitter-based 'commentstring'. Recompute every time for a proper
  -- dot-repeat. In Visual and sometimes Normal mode it uses start position.
  toggle_lines(lnum_from, lnum_to, vim.api.nvim_win_get_cursor(0), opts)
  return ''
end

-- added for use with operatorfunc for align mappings
local function operator_align(mode)
  return operator(mode, { align = true, trim = false })
end
local function operator_align_trim(mode)
  return operator(mode, { align = true, trim = true })
end
local function operator_trim(mode)
  return operator(mode, { align = false, trim = true })
end

local function init()
  vim.keymap.del('n', 'gcc')

  vim.keymap.set({ 'x' }, 'gc', function()
    return require('comment').operator(nil, { align = false, trim = true })
  end, { expr = true, desc = 'Toggle comment' })

  vim.keymap.set({ 'x' }, 'gC', function()
    return require('comment').operator(nil, { align = true, trim = true })
  end, { expr = true, desc = 'Toggle comment' })

  vim.keymap.set('n', 'gc', function()
    return require('comment').operator(nil, { align = false, trim = true }) .. '_'
  end, { expr = true, desc = 'Toggle comment line' })
  vim.keymap.set('n', 'gC', function()
    return require('comment').operator(nil, { align = true, trim = true }) .. '_'
  end, { expr = true, desc = 'Toggle comment line' })
end

return {
  operator = operator,
  operator_align = operator_align,
  operator_align_trim = operator_align_trim,
  operator_trim = operator_trim,
  init = init,
}
