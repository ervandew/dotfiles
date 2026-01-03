local M = {}

-- limiting to comma separated value files
local csv_delimiter = ','

-- vim compatible pattern to match csv values
local csv_pattern = '\\%(\\%(\\%(\\s*"\\%([^"]\\|""\\)*"\\s*\\)\\%(,\\|$\\)\\)\\|\\%([^,]*\\%(,\\|$\\)\\)\\)'

local function columns(line)
  -- naive split
  local list = vim.split(line, csv_delimiter)

  -- now handle quoted values containing the csv_delimiter
  local cols = {}
  local partial = nil
  for _, item in ipairs(list) do
    if partial ~= nil then
      partial = partial .. csv_delimiter .. item
      if #item >= 1 and item:sub(#item) == '"' then
        table.insert(cols, partial)
        partial = nil
      end
    elseif #item >= 1 and item:sub(1, 1) == '"' and item:sub(#item) ~= '"' then
      -- incomplete quoted column, store for merging with the rest of the value
      partial = item
    else
      table.insert(cols, item)
    end
  end
  if partial ~= nil then
    table.insert(cols, partial)
  end
  return cols
end

M.column = function()
  local pos = vim.fn.col('.')
  if pos == 1 then
    return 1
  end

  local cols = columns(vim.fn.getline('.'))
  if pos >= vim.fn.col('$') then
    return #cols
  end

  local chars = 0
  for index, col in ipairs(cols) do
    chars = chars + #col + #csv_delimiter
    if pos <= chars then
      return index
    end
  end
end

M.column_name = function(col)
  return columns(vim.fn.getline(1))[col]
end

-- Note: csv align code taken from decisive.nvim
-- (https://github.com/emmanueltouzery/decisive.nvim), with some some stuff
-- stripped out, since decisive doesn't seem to be maintained anymore
M.align_clear = function()
  local ns = vim.api.nvim_create_namespace('__align_csv')
  -- clear existing extmarks
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

  if vim.b[0].__align_csv_autocmd ~= nil then
    vim.api.nvim_del_autocmd(vim.b[0].__align_csv_autocmd)
    vim.b[0].__align_csv_autocmd = nil
  end
end

M.align = function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  if #lines == 0 then
    return
  end

  M.align_clear()
  local ns = vim.api.nvim_create_namespace('__align_csv')
  local col_max_lengths = {}
  local col_lengths = {}
  for line_idx, line in ipairs(lines) do
    local cols = columns(line)
    local col_lengths_line = {}
    for col_idx, col in ipairs(cols) do
      -- include the delimiter for display width, very important for tabs which
      -- have variable width
      local display_width = vim.fn.strdisplaywidth(col .. csv_delimiter)
      table.insert(col_lengths_line, {display_width, #col})
      if not col_max_lengths[col_idx] or
         display_width + 1 > col_max_lengths[col_idx]
      then
        col_max_lengths[col_idx] = display_width + 1
      end
    end
    col_lengths[line_idx] = col_lengths_line
  end
  for line_idx, line_cols_info in ipairs(col_lengths) do
    local col_from_start = 0
    local row_hl_name = 'CsvFill'
    for col_idx, col_info in ipairs(line_cols_info) do
      local col_display_width = col_info[1]
      local col_length = col_info[2]
      if col_idx < #line_cols_info then
        local extmark_col = col_from_start + col_length + 1
        if col_display_width < col_max_lengths[col_idx] then
          vim.api.nvim_buf_set_extmark(0, ns, line_idx - 1, extmark_col, {
            virt_text = { {
              string.rep(' ', col_max_lengths[col_idx] - col_display_width),
              row_hl_name
            } },
            virt_text_pos = 'inline',
          })
        else
          -- no need for virtual text, the column is full. but add it anyway
          -- because of the previous/next column jumps
          vim.api.nvim_buf_set_extmark(0, ns, line_idx - 1, extmark_col, {
            virt_text = {{'', row_hl_name}},
            virt_text_pos = 'inline',
          })
        end
        col_from_start = extmark_col
      end
    end
  end

  if vim.b[0].__align_csv_autocmd == nil then
    vim.b[0].__align_csv_autocmd = vim.api.nvim_create_autocmd(
      {'InsertLeave', 'TextChanged'},
      { callback = require('csv').align }
    )
  end
end

M.next_col = function()
  local ns = vim.api.nvim_create_namespace('__align_csv')
  local next_mark = vim.api.nvim_buf_get_extmarks(
    0, ns, {vim.fn.line('.') - 1, vim.fn.col('.') + 1}, -1, {limit = 1}
  )
  if #next_mark == 1 then
    if next_mark[1][2] + 1 > vim.fn.line('.') then
      -- moving to next line. the first column is the start of the line
      vim.fn.setpos('.', {0, next_mark[1][2] + 1, 1, 0})
    else
      vim.fn.setpos('.', {0, next_mark[1][2]  +1, next_mark[1][3] + 1, 0})
    end
  end
end

M.prev_col = function()
  local ns = vim.api.nvim_create_namespace('__align_csv')
  local next_mark = vim.api.nvim_buf_get_extmarks(
    0, ns, {vim.fn.line('.') - 1, vim.fn.col('.') - 2}, 0, {limit = 1}
  )
  if vim.fn.col('.') == 1 then
    next_mark = vim.api.nvim_buf_get_extmarks(
      0, ns, {vim.fn.line('.') - 1, vim.fn.col('.') - 1}, 0, {limit = 1}
    )
  end
  if #next_mark == 1 then
    if next_mark[1][2] + 1 < vim.fn.line('.') and vim.fn.col('.') > 1 then
      -- the previous mark is on the previous line, but don't forget about the
      -- first column of the line
      vim.fn.setpos('.', {0, vim.fn.line('.'), 1, 0})
    else
      vim.fn.setpos('.', {0, next_mark[1][2] + 1, next_mark[1][3] + 1, 0})
    end
  else
    -- go to the beginning of the line
    vim.fn.setpos('.', {0, vim.fn.line('.'), 1, 0})
  end
end

M.add = function(opts)
  local cols = columns(vim.fn.getline('.'))
  local col = M.column()
  if opts.bang then
    col = col - 1
  end

  local pattern
  if col == 0 then
    pattern = '^'
  elseif col == #cols then
    pattern = '$'
  else
    pattern = csv_pattern .. '\\{' .. col .. '\\}\\zs'
  end
  local wv = vim.fn.winsaveview()
  vim.cmd('keeppatterns %s/' .. vim.fn.escape(pattern, '/') .. '/' .. csv_delimiter .. '/')
  vim.fn.winrestview(wv)
end

M.del = function()
  local column = M.column()
  local pattern = csv_pattern
  if column == 1 then
    pattern = '^' .. pattern
  else
    local cols = columns(vim.fn.getline('.'))
    -- last column, we want to remove the trailing delimiter of the previous
    -- column
    if column == #cols then
      pattern = '^.*\\%(\\%(\\%(\\s*"\\%([^"]\\|""\\)*"\\s*\\),\\)\\|\\%([^,]*\\)\\)\\zs,.*'
    -- every column except the first and last, skip over all previous columns
    -- and then match the current one
    else
      pattern = pattern .. '\\{' .. (column - 1) .. '\\}\\zs' .. pattern
    end
  end

  local wv = vim.fn.winsaveview()
  vim.cmd('keeppatterns %s/' .. vim.fn.escape(pattern, '/') .. '//')
  vim.fn.winrestview(wv)
end

M.init = function()
  vim.api.nvim_create_autocmd('BufWinEnter', {
    pattern = '*.csv',
    callback = function()
      vim.wo.sidescrolloff = 40
      -- virtualedit breaks yanking, and possibly other features
      vim.wo.virtualedit = 'none'
      vim.wo.wrap = false

      local csv = require('csv')
      csv.align()
      vim.api.nvim_buf_create_user_command(0, 'Align', csv.align, { nargs = 0})
      vim.api.nvim_buf_create_user_command(0, 'AlignClear', csv.align_clear, { nargs = 0 })
      vim.api.nvim_buf_create_user_command(0, 'Add', csv.add, { nargs = 0, bang = true })
      vim.api.nvim_buf_create_user_command(0, 'Del', csv.del, { nargs = 0 })
      vim.keymap.set('n', 'B', csv.prev_col, {buffer = true, silent = true})
      vim.keymap.set('n', 'W', csv.next_col, {buffer = true, silent = true})
      vim.api.nvim_set_hl(0, 'CsvFill', { fg = '#333333', undercurl = true })
    end,
  })
end

return M
