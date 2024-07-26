local M = {}
local nodes_by_lang = {
  python = {
    call = { path = { 'arguments', '*' }, comma_separated = true },
    class_definition = {
      path = { 'superclasses', '*' },
      comma_separated = true,
    },
    dictionary = { path = {'*'}, comma_separated = true },
    dictionary_comprehension = { path = { '*' } },
    generator_expression = { path = { '*' } },
    list = { path = { '*' }, comma_separated = true },
    list_comprehension = { path = { '*' } },
    set = { path = { '*' }, comma_separated = true },
    set_comprehension = { path = { '*' } },
    tuple = { path = { '*' }, comma_separated = true },
    function_definition = {
      path = { 'parameters', '*' },
      comma_separated = true,
    },
    import_from_statement = {
      path = { 'name' },
      pre = '(',
      post = ')',
      comma_separated = true,
    },
  }
}

local function _wrap(lnum, rule, children)
  local cr = vim.api.nvim_replace_termcodes('<cr>', true, false, true)
  local esc = vim.api.nvim_replace_termcodes('<esc>', true, false, true)
  local num_lines = #children
  -- loop over our results in reverse
  for i = #children, 1, -1 do
    local line_start = children[i]['line_start']
    local col_start = children[i]['col_start']
    local line_end = children[i]['line_end']
    local col_end = children[i]['col_end']

    -- if we are wrapping a multiline elment, then ensure we add the additional
    -- lines to what we will reformat at the end.
    if line_end > line_start then
      num_lines = num_lines + (line_end - line_start)
    end

    -- for the last child, wrap the end of it
    if i == #children then
      local suffix = ''
      if rule.post then
        suffix = cr .. rule.post
      else
        suffix = cr
      end

      -- handle wrapping around a trailing comma, or adding one
      local post = string.sub(vim.fn.getline(line_end + 1), col_end, col_end)
      if post == ',' then
        col_end = col_end + 1
      elseif rule.comma_separated == true then
        suffix = ',' .. suffix
      end

      vim.fn.cursor(line_end, col_end)
      vim.cmd.normal('i' .. suffix .. esc)
      vim.fn.cursor(lnum, 0)
    end

    local prefix = i == 1 and rule.pre or ''
    local pre = string.sub(vim.fn.getline(lnum), col_start - 1, col_start - 1)

    -- wrap before any leading space unless we are adding a prefix
    if pre == ' ' and prefix == '' then
      col_start = col_start - 1
    end

    vim.fn.cursor(0, col_start)
    vim.cmd.normal('i' .. prefix .. cr .. esc)
    vim.fn.cursor(lnum, 0)
  end
  vim.cmd('silent normal =' .. (num_lines + 1) .. 'j')
end

local function _unwrap(lnum, rule, children)
  local last_lnum = lnum
  for _, child in ipairs(children) do
    local line_end = child['line_end']
    if line_end > last_lnum then
      last_lnum = line_end
    end
  end

  local lines = last_lnum - lnum + 1

  local next_line = vim.fn.getline(last_lnum + 1)
  local next_line_close = false
  if rule.post then
    if string.find(next_line, rule.post, 1, true) then
      lines = lines + 1
    end
  else
    if next_line:match('%s*[}%)%]][:,]?%s*\\?$') then
      next_line_close = true
      lines = lines + 1
    end
  end

  local line = vim.fn.getline(lnum)
  local last_line = vim.fn.getline(last_lnum)
  if last_line:match(',$') then
    last_line = string.gsub(last_line, ',$', '')
    vim.fn.setline(last_lnum, last_line)
  end

  vim.fn.cursor(lnum, 0)
  vim.cmd.normal(lines .. 'J')

  -- remove any leading space added when joining lines
  local leading_line = string.sub(vim.fn.getline(lnum), 1, #line + 1)
  if leading_line:match(' $') then
    vim.fn.cursor(lnum, #leading_line)
    vim.cmd.normal('x')
  end

  -- remove any trailing space added when joining lines
  if next_line_close then
    local trailing_line = vim.fn.getline(lnum)
    local closing = next_line:gsub(' ', '')
    local index = string.find(trailing_line, ' ' .. closing, 1, true)
    if index == (#trailing_line - #closing) then
      vim.fn.cursor(lnum, index)
      vim.cmd.normal('x')
    end
  end

  -- remove any rule prefix that may exist
  if rule.pre then
    local index = string.find(line, rule.pre, 1, true)
    if index == (#line - (#rule.pre - 1)) then
      vim.fn.cursor(lnum, index)
      vim.cmd.normal(#rule.pre .. 'x')
    end
  end

  -- remove any rule suffix that may exist
  if rule.post then
    local post_line = vim.fn.getline(lnum)
    local index = string.find(post_line:reverse(), rule.post:reverse(), 1, true)
    if index == 1 then
      vim.fn.cursor(lnum, #post_line - #rule.post + 1)
      vim.cmd.normal(#rule.post .. 'x')
    end
  end
end

local function _walk(lnum, node, rule)
  local children = {}
  local path = rule['path']
  local wrap = true
  for child, child_field in node:iter_children() do
    if child:named() then
      local key = child_field or child:type()
      if key == path[1] or path[1] == '*' then
        if #path > 1 then
          _walk(lnum, child, vim.tbl_extend(
            'force',
            rule,
            {path = vim.list_slice(path, 2, #path)}
          ))
          break
        end
        local line_start, col_start = child:start()
        local line_end, col_end = child:end_()
        if (line_start + 1) ~= lnum then
          wrap = false
        end

        children[#children + 1] = {
          line_start = line_start + 1,
          line_end = line_end + 1,
          col_start = col_start + 1,
          col_end = col_end + 1,
        }
      end
    end
  end

  if #children ~= 0 then
    if wrap then
      _wrap(lnum, rule, children)
    else
      _unwrap(lnum, rule, children)
    end
  end
end

M.eval = function()
  local nodes = nodes_by_lang[vim.o.ft]
  if nodes == nil then
    return
  end

  local lnum = vim.fn.line('.')
  local cnum = vim.fn.col('.')
  local node = vim.treesitter.get_node()
  local type = nil
  while node ~= nil and node:start() == lnum - 1 do
    local check_type = node:type()
    if nodes[check_type] ~= nil then
      type = check_type
      break
    end
    node = node:parent()
  end
  if node ~= nil and type ~= nil then
    _walk(lnum, node, nodes[type])
  end

  vim.fn.cursor(lnum, cnum)
end

return M
