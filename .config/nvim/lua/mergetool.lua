local M = {}

-- .gitconfig
--   [merge]
--     tool = nvim
--   [mergetool "nvim"]
--     cmd = nvim -d -O3 "$LOCAL" "$BASE" "$REMOTE" "$MERGED" -c "Mergetool"
M.setup = function()
  if vim.fn.bufnr('$') ~= 4 then
    vim.api.nvim_echo(
      {{ 'Unexpected number of buffers: ' .. vim.fn.bufnr('$'), 'Error' }},
      true,
      {}
    )
    return
  end

  if vim.fn.winnr('$') ~= 3 then
    vim.api.nvim_echo(
      {{ 'Unexpected number of windows: ' .. vim.fn.winnr('$'), 'Error' }},
      true,
      {}
    )
    return
  end

  -- relies on repo alias from my .gitconfg
  local branch = vim.fn.split(vim.fn.systemlist('git repo')[1], ':')[2]
  local files = {
    REMOTE = 'MERGING IN',
    BASE = 'COMMON BASE',
    LOCAL = 'CURRENT BRANCH',
  }
  if branch == 'rebase' then
    -- with a rebase the current branch becomes the REMOTE since it is applied
    -- last, and the LOCAL is the other branch that we are attempting to rebase
    -- on top of.
    files = {
      REMOTE = 'CURRENT BRANCH',
      BASE = 'COMMON BASE',
      LOCAL = 'REBASE ONTO',
    }
  end

  for name, display in pairs(files) do
    local pattern = '*_' .. name .. '_*'
    local winnr = vim.fn.bufwinnr(pattern)
    if winnr == -1 then
      vim.api.nvim_echo(
        {{ 'Missing expected file: ' .. pattern, 'Error' }},
        false,
        {}
      )
      return
    end
    vim.cmd(winnr .. 'winc w')
    vim.wo.statusline = display
  end

  local merge = vim.fn.bufname(4)
  vim.cmd('bot diffsplit ' .. merge)
end

return M
