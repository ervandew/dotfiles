return {
  {
    'emmanueltouzery/decisive.nvim',
    config = function()
      vim.api.nvim_create_autocmd('BufWinEnter', {
        pattern = '*.csv',
        callback = function()
          vim.wo.sidescrolloff = 40
          -- virtualedit breaks yanking, and possibly other features
          vim.wo.virtualedit = 'none'
          vim.wo.wrap = false

          local decisive = require('decisive')
          decisive.setup({})
          decisive.align_csv({ csv_separator = ',' })

          vim.api.nvim_buf_create_user_command(0, 'CsvAlign', function()
            require('decisive').align_csv({})
          end, { nargs = 0 })

          vim.api.nvim_buf_create_user_command(0, 'CsvAlignClear', function()
            require('decisive').align_csv_clear({})
          end, { nargs = 0 })

          vim.keymap.set(
            'n',
            '[c',
            decisive.align_csv_prev_col,
            {buffer = true, silent = true}
          )
          vim.keymap.set(
            'n',
            ']c',
            decisive.align_csv_next_col,
            {buffer = true, silent = true}
          )

          vim.api.nvim_set_hl(0, 'CsvFillHl', { fg = '#323242', undercurl = true })
        end,
      })
    end,
  },
  -- decisive by itself doesn't work very well other than aligning the columns,
  -- so include csv.vim for a more complete set of features
  -- also used in custom status line to show the current column name and number
  {
    'chrisbra/csv.vim',
    config = function()
      -- set a default delimiter to suppress warnings
      vim.g.csv_delim = ','

      vim.api.nvim_create_autocmd('BufWinEnter', {
        pattern = '*.csv',
        callback = function()
          -- csv.vim uses CSV* command names, so create Csv* commands for just
          -- the ones i plan to use.
          vim.api.nvim_buf_create_user_command(0, 'CsvAdd', function(opts)
            vim.cmd('CSVAddColumn ' .. opts.args)
          end, { nargs = '*' })
          vim.api.nvim_buf_create_user_command(0, 'CsvDel', function()
            vim.cmd('CSVDeleteColumn')
          end, { nargs = 0 })
          vim.api.nvim_buf_create_user_command(0, 'CsvMove', function(opts)
            vim.cmd('CSVMoveColumn ' .. opts.args)
          end, { nargs = '*' })
        end,
      })
    end
  }
}
