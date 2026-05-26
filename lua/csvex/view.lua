local M = {}
local actions = require("csvex.actions")

function M.render_line(bufnr, lnum, fields, ns_id, max_widths, leftcol)
  max_widths = max_widths or {}
  local last_lnum = vim.api.nvim_buf_line_count(bufnr) - 1

  if last_lnum > 0 then
    local last_line_text = vim.api.nvim_buf_get_lines(bufnr, last_lnum, last_lnum + 1, false)[1]
    if last_line_text == "" then
      last_lnum = last_lnum - 1
    end
  end

  if lnum > last_lnum then
    return
  end

  local join_left = (lnum == last_lnum) and "└─" or "├─"
  local full_border = join_left
  local full_top_border = "┌─"

  vim.api.nvim_buf_set_extmark(bufnr, ns_id, lnum, 0, {
    virt_text = { { "│", "CsvexSeparator" }, { " ", "CsvexSeparator" } },
    virt_text_pos = "inline",
    right_gravity = false,
    priority = 200,
  })

  for i, field in ipairs(fields) do
    local start_pos = field.start - 1
    local end_pos = start_pos + #field.text
    local target_width = max_widths[i] or 0
    local current_width = field.display_width or vim.api.nvim_strwidth(field.text)
    local padding_size = math.max(target_width - current_width, 0)
    local padding = string.rep(" ", padding_size)

    local dashes = string.rep("─", target_width)

    if i < #fields then
      local join_cross = (lnum == last_lnum) and "─┴─" or "─┼─"
      full_border = full_border .. dashes .. join_cross
      full_top_border = full_top_border .. dashes .. "─┬─"

      vim.api.nvim_buf_set_extmark(bufnr, ns_id, lnum, end_pos, {
        virt_text = { { padding .. " ", "CsvexSeparator" } },
        virt_text_pos = "inline",
      })

      vim.api.nvim_buf_set_extmark(bufnr, ns_id, lnum, end_pos, {
        end_col = end_pos + 1,
        conceal = "│",
        hl_group = "CsvexSeparator",
      })

      vim.api.nvim_buf_set_extmark(bufnr, ns_id, lnum, end_pos + 1, {
        virt_text = { { " ", "CsvexSeparator" } },
        virt_text_pos = "inline",
      })
    else
      local join_right = (lnum == last_lnum) and "─┘" or "─┤"
      full_border = full_border .. dashes .. join_right
      full_top_border = full_top_border .. dashes .. "─┐"

      vim.api.nvim_buf_set_extmark(bufnr, ns_id, lnum, end_pos, {
        virt_text = { { padding, "CsvexSeparator" }, { " │", "CsvexSeparator" } },
        virt_text_pos = "inline",
      })
    end
  end

  local display_border = vim.fn.strcharpart(full_border, leftcol)
  local display_top_border = vim.fn.strcharpart(full_top_border, leftcol)

  vim.api.nvim_buf_set_extmark(bufnr, ns_id, lnum, 0, {
    virt_lines = { { { display_border, "CsvexBorder" } } },
    virt_lines_above = false,
  })

  if lnum == 0 then
    vim.api.nvim_buf_set_extmark(bufnr, ns_id, lnum, 0, {
      virt_lines = { { { display_top_border, "CsvexBorder" } } },
      virt_lines_above = true,
    })
  end
end

function M.update_winbar()
  local field, idx = actions.get_current_field()
  if field then
    local winid = vim.api.nvim_get_current_win()
    local wininfo = vim.fn.getwininfo(winid)[1]
    local textoff = wininfo and wininfo.textoff or 0
    local padding = string.rep(" ", textoff)

    local header_text = ""
    local metrics = require("csvex.metrics")
    if metrics.row_cache[0] and metrics.row_cache[0][idx] then -- 0-indexed
      local h_field = metrics.row_cache[0][idx]
      if h_field.text and h_field.text ~= "" and h_field.text ~= "  " then
        header_text = string.format(" (%s)", vim.trim(h_field.text))
      end
    end

    local bar_text =
      string.format("%s%%#CsvexSeparator# Cell %d%s: %%#Normal# %s ", padding, idx, header_text, field.text)
    vim.wo.winbar = bar_text
  else
    vim.wo.winbar = ""
  end
end

return M
