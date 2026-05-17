local M = {}

local keymap = require("csvex.keymap")
local metrics = require("csvex.metrics")
local parser = require("csvex.parser")
local view = require("csvex.view")

local ns_id = vim.api.nvim_create_namespace("csvex_view")

function M.attach(bufnr)
  if vim.b[bufnr].csvex_attached then
    return
  end
  vim.b[bufnr].csvex_attached = true

  vim.api.nvim_buf_call(bufnr, function()
    keymap.setup_keys()
  end)

  require("csvex.config.sys_applier").apply_to_buffer(bufnr, require("csvex.config.defaults").sys)

  metrics.compute_all(bufnr, parser)
  print("CSV Max Widths: ", vim.inspect(metrics.max_width))

  vim.api.nvim_set_decoration_provider(ns_id, {
    on_win = function(_, winid, win_bufnr, toprow, botrow)
      if win_bufnr ~= bufnr then
        return false
      end

      local leftcol = vim.api.nvim_win_call(winid, function()
        return vim.fn.winsaveview().leftcol
      end)

      local start_row = math.max(0, toprow - 1)
      vim.api.nvim_buf_clear_namespace(bufnr, ns_id, start_row, botrow + 1)

      for lnum = start_row, botrow do
        local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1]
        if line then
          local fields = parser.parse_line(line)
          metrics.update_line(lnum, fields)
          view.render_line(bufnr, lnum, fields, ns_id, metrics.max_width, leftcol)
        end
      end
      return false
    end,
  })

  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      vim.fn.winrestview({ topline = 1 })
      vim.cmd([[execute "normal! \<C-y>\<C-y>\<C-y>"]])
      view.update_winbar()
    end
  end)

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    buffer = bufnr,
    callback = function()
      view.update_winbar()

      vim.schedule(function()
        local current_line = vim.fn.line(".")
        local last_line = vim.fn.line("$")
        local win_height = vim.fn.winheight(0)
        local cursor_winline = vim.fn.winline()

        if current_line == 1 then
          local view_opt = vim.fn.winsaveview()
          if view_opt.topline > 1 or cursor_winline == 1 then
            vim.fn.winrestview({ topline = 1 })
            vim.cmd([[execute "normal! \<C-y>\<C-y>\<C-y>"]])
          end
        elseif current_line == last_line then
          if last_line > win_height and cursor_winline >= win_height then
            vim.cmd([[execute "normal! \<C-e>"]])
          end
        end
      end)
    end,
  })

  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = function(_, _, _, firstline, lastline, new_lastline)
      metrics.update_delta(bufnr, parser, firstline, lastline, new_lastline)

      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
          view.update_winbar()
        end
      end)
    end,
  })
end

return M
