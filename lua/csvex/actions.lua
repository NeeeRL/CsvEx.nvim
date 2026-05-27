local M = {}
local metrics = require("csvex.metrics")

function M.jump_next_cell()
  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  local col = vim.api.nvim_win_get_cursor(0)[2] -- 0-indexed
  local row_data = metrics.row_cache[lnum]
  if not row_data then
    return
  end
  for _, field in ipairs(row_data) do
    if field.start - 1 > col then
      vim.api.nvim_win_set_cursor(0, { lnum + 1, field.start - 1 })
      return
    end
  end
end

function M.jump_prev_cell()
  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local row_data = metrics.row_cache[lnum]
  if not row_data then
    return
  end
  for i = #row_data, 1, -1 do
    local field = row_data[i]
    if (field.start - 1) < col then
      vim.api.nvim_win_set_cursor(0, { lnum + 1, field.start - 1 })
      return
    end
  end
end

function M.jump_down_cell()
  local field, col_idx = M.get_current_field()
  if not field then
    return
  end

  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  local main_buf = vim.api.nvim_get_current_buf()
  local last_lnum = vim.api.nvim_buf_line_count(main_buf) - 1

  -- 一番下の行なら何もしない
  if lnum >= last_lnum then
    return
  end

  -- 下の行のキャッシュデータを取得
  local next_row_data = require("csvex.metrics").row_cache[lnum + 1]

  if next_row_data and next_row_data[col_idx] then
    local target_field = next_row_data[col_idx]
    vim.api.nvim_win_set_cursor(0, { lnum + 2, math.max(0, target_field.start - 1) })
  end
end

function M.jump_up_cell()
  local field, col_idx = M.get_current_field()
  if not field then
    return
  end

  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1

  -- 一番上の行なら何もしない
  if lnum <= 0 then
    return
  end

  -- 上の行のキャッシュデータを取得
  local prev_row_data = require("csvex.metrics").row_cache[lnum - 1]

  if prev_row_data and prev_row_data[col_idx] then
    local target_field = prev_row_data[col_idx]
    vim.api.nvim_win_set_cursor(0, { lnum, math.max(0, target_field.start - 1) })
  end
end
function M.jump_first_cell_in_row()
  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  local row_data = require("csvex.metrics").row_cache[lnum]
  if row_data and row_data[1] then
    vim.api.nvim_win_set_cursor(0, { lnum + 1, math.max(0, row_data[1].start - 1) })
  end
end

function M.jump_last_cell_in_row()
  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  local row_data = require("csvex.metrics").row_cache[lnum]
  if row_data and #row_data > 0 then
    local last_field = row_data[#row_data]
    vim.api.nvim_win_set_cursor(0, { lnum + 1, math.max(0, last_field.start - 1) })
  end
end

function M.jump_top_left_cell()
  local row_data = require("csvex.metrics").row_cache[0]
  if row_data and row_data[1] then
    vim.api.nvim_win_set_cursor(0, { 1, math.max(0, row_data[1].start - 1) })
  end
end

function M.jump_bottom_left_cell()
  local main_buf = vim.api.nvim_get_current_buf()
  local last_lnum = vim.api.nvim_buf_line_count(main_buf) - 1
  local row_data = require("csvex.metrics").row_cache[last_lnum]
  if row_data and row_data[1] then
    vim.api.nvim_win_set_cursor(0, { last_lnum + 1, math.max(0, row_data[1].start - 1) })
  end
end

function M.clear_cell()
  local field, _ = M.get_current_field()
  if not field then
    return
  end

  local main_buf = vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  local line = vim.api.nvim_buf_get_lines(main_buf, lnum, lnum + 1, false)[1]

  local prefix = string.sub(line, 1, field.start - 1)
  local suffix = string.sub(line, field.start + #field.text)

  vim.api.nvim_buf_set_lines(main_buf, lnum, lnum + 1, false, { prefix .. "  " .. suffix })

  local new_cursor_col = math.max(0, field.start - 1)
  vim.api.nvim_win_set_cursor(0, { lnum + 1, new_cursor_col })

  require("csvex.metrics").compute_all(main_buf, require("csvex.parser"))
  require("csvex.view").update_winbar()
end

function M.get_current_field()
  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local row_data = metrics.row_cache[lnum]

  if not row_data or #row_data == 0 then
    return { text = "", start = 1 }, 1
  end

  for i, field in ipairs(row_data) do
    local next_field = row_data[i + 1]
    local field_end = next_field and (next_field.start - 2) or 999999
    if (field.start - 1) <= col and col <= field_end then
      return field, i
    end
  end
  return nil, nil
end

function M.edit_cell(isClearText)
  local field, col_idx = M.get_current_field()
  if not field then
    return
  end

  local main_buf = vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1

  local float_buf = vim.api.nvim_create_buf(false, true)

  local initial_text = field.text
  if initial_text == "  " or isClearText then
    initial_text = ""
  end

  vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, { initial_text })

  local winid = vim.api.nvim_get_current_win()
  local win_width = vim.api.nvim_win_get_width(winid)
  local win_height = vim.api.nvim_win_get_height(winid)

  local prefix_title = string.format(" [R%d:C%d] ", lnum + 1, col_idx)
  local cfg = require("csvex.config").get()

  local float_height = 1
  local target_row = cfg.bar_position == "bottom" and (win_height - 2) or -1

  local win_opts = {
    relative = "win",
    win = winid,
    anchor = cfg.bar_position == "bottom" and "SW" or "NW",
    row = target_row,
    col = 0,
    width = math.max(10, win_width - 2),
    height = float_height,
    style = "minimal",
    border = "rounded",
    title = prefix_title,
    title_pos = "left",
  }

  local float_win = vim.api.nvim_open_win(float_buf, true, win_opts)

  vim.api.nvim_set_option_value("winhl", "NormalFloat:CsvexFormulaBar,FloatBorder:CsvexSeparator", { win = float_win })

  if cfg.initial_mode == "insert" or isClearText then
    vim.cmd("startinsert!")
  else
    vim.api.nvim_win_set_cursor(float_win, { 1, 0 })
  end
  local augroup = vim.api.nvim_create_augroup("CsvexFloatResize_" .. float_win, { clear = true })

  local function update_layout()
    if not vim.api.nvim_buf_is_valid(float_buf) or not vim.api.nvim_win_is_valid(float_win) then
      return true
    end

    local cur_win_width = vim.api.nvim_win_get_width(winid)
    local cur_win_height = vim.api.nvim_win_get_height(winid)

    local line_count = vim.api.nvim_buf_line_count(float_buf)
    local new_height = math.min(line_count, 10)

    local t_row = cfg.bar_position == "bottom" and (cur_win_height - 2) or -1

    pcall(vim.api.nvim_win_set_config, float_win, {
      relative = "win",
      win = winid,
      anchor = cfg.bar_position == "bottom" and "SW" or "NW",
      row = t_row,
      col = 0,
      width = math.max(10, cur_win_width - 2),
      height = new_height,
    })

    if line_count <= 10 then
      vim.api.nvim_win_call(float_win, function()
        vim.fn.winrestview({ topline = 1 })
      end)
    end
  end

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = augroup,
    buffer = float_buf,
    callback = update_layout,
  })

  vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    group = augroup,
    callback = update_layout,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = augroup,
    pattern = tostring(float_win),
    callback = function()
      pcall(vim.api.nvim_del_augroup_by_id, augroup)
    end,
  })

  local function save_and_close()
    local new_text = vim.api.nvim_buf_get_lines(float_buf, 0, 1, false)[1]

    if new_text == "" then
      new_text = "  "
    end

    local line = vim.api.nvim_buf_get_lines(main_buf, lnum, lnum + 1, false)[1]
    local prefix = string.sub(line, 1, field.start - 1)
    local suffix = string.sub(line, field.start + #field.text)
    vim.api.nvim_buf_set_lines(main_buf, lnum, lnum + 1, false, { prefix .. new_text .. suffix })

    if vim.fn.mode() == "i" then
      vim.cmd("stopinsert")
    end
    pcall(vim.api.nvim_win_close, float_win, true)

    require("csvex.metrics").compute_all(main_buf, require("csvex.parser"))
    require("csvex.view").update_winbar()

    vim.schedule(function()
      vim.api.nvim_win_set_cursor(0, { lnum + 1, #prefix })
    end)
  end

  if cfg.enter_to_save then
    vim.keymap.set({ "i", "n" }, "<CR>", save_and_close, { buffer = float_buf, silent = true })
  end

  local function cmd_quit(opts)
    if opts and opts.bang then
      pcall(vim.api.nvim_win_close, float_win, true)
      return
    end

    local current_text = vim.api.nvim_buf_get_lines(float_buf, 0, 1, false)[1] or ""

    if current_text ~= initial_text then
      vim.notify("E37: No write since last change (add ! to override)", vim.log.levels.ERROR)
      return
    end
    pcall(vim.api.nvim_win_close, float_win, true)
  end

  vim.keymap.set("n", "<CR>", save_and_close, { buffer = float_buf, silent = true })

  vim.keymap.set("n", "q", function()
    cmd_quit({ bang = true })
  end, { buffer = float_buf, silent = true })

  if cfg.insert_enter_to_save then
    vim.keymap.set("i", "<CR>", save_and_close, { buffer = float_buf, silent = true })
  end
end

function M.change_cell()
  M.edit_cell(true)
end

function M.delete_column()
  local field, col_idx = M.get_current_field()
  if not field or not col_idx then
    return
  end

  local main_buf = vim.api.nvim_get_current_buf()
  local last_lnum = vim.api.nvim_buf_line_count(main_buf) - 1
  local parser = require("csvex.parser")
  local new_lines = {}

  -- 全行に対して対象列のデータを削除
  for lnum = 0, last_lnum do
    local row_data = metrics.row_cache[lnum]
    if not row_data then
      local line = vim.api.nvim_buf_get_lines(main_buf, lnum, lnum + 1, false)[1] or ""
      row_data = parser.parse_line(line)
    end

    local new_fields = {}
    for i, f in ipairs(row_data) do
      if i ~= col_idx then
        table.insert(new_fields, f.text)
      end
    end

    -- 全ての列を削除してしまった場合は、最低1つの空セルを維持する
    if #new_fields == 0 then
      table.insert(new_fields, "  ")
    end

    table.insert(new_lines, table.concat(new_fields, ","))
  end

  -- バッファ全体を一度に書き換え
  vim.api.nvim_buf_set_lines(main_buf, 0, -1, false, new_lines)

  -- メトリクスを再計算して描画を更新
  metrics.compute_all(main_buf, parser)
  require("csvex.view").update_winbar()

  -- バイト位置のズレを補正し、論理的な列インデックスにカーソルを復帰させる
  vim.schedule(function()
    local cur_lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
    local new_row_data = metrics.row_cache[cur_lnum]
    if new_row_data then
      -- 削除により列が減った場合、末尾の列に合わせる
      local target_col_idx = math.min(col_idx, #new_row_data)
      local target_field = new_row_data[target_col_idx]
      if target_field then
        vim.api.nvim_win_set_cursor(0, { cur_lnum + 1, math.max(0, target_field.start - 1) })
      end
    end
  end)
end

function M.insert_column_right()
  local field, col_idx = M.get_current_field()
  if not col_idx then
    return
  end

  local main_buf = vim.api.nvim_get_current_buf()
  local last_lnum = vim.api.nvim_buf_line_count(main_buf) - 1
  local parser = require("csvex.parser")
  local new_lines = {}

  for lnum = 0, last_lnum do
    local row_data = metrics.row_cache[lnum]
    if not row_data then
      local line = vim.api.nvim_buf_get_lines(main_buf, lnum, lnum + 1, false)[1] or ""
      row_data = parser.parse_line(line)
    end

    local new_fields = {}
    for i, f in ipairs(row_data) do
      table.insert(new_fields, f.text)
      -- 現在の列の右に空セルを挿入
      if i == col_idx then
        table.insert(new_fields, "  ")
      end
    end
    table.insert(new_lines, table.concat(new_fields, ","))
  end

  vim.api.nvim_buf_set_lines(main_buf, 0, -1, false, new_lines)
  metrics.compute_all(main_buf, parser)
  require("csvex.view").update_winbar()

  vim.schedule(function()
    local cur_lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
    local new_row_data = metrics.row_cache[cur_lnum]
    if new_row_data and new_row_data[col_idx + 1] then
      vim.api.nvim_win_set_cursor(0, { cur_lnum + 1, math.max(0, new_row_data[col_idx + 1].start - 1) })
    end
  end)
end

function M.insert_column_left()
  local field, col_idx = M.get_current_field()
  if not col_idx then
    return
  end

  local main_buf = vim.api.nvim_get_current_buf()
  local last_lnum = vim.api.nvim_buf_line_count(main_buf) - 1
  local parser = require("csvex.parser")
  local new_lines = {}

  for lnum = 0, last_lnum do
    local row_data = metrics.row_cache[lnum]
    if not row_data then
      local line = vim.api.nvim_buf_get_lines(main_buf, lnum, lnum + 1, false)[1] or ""
      row_data = parser.parse_line(line)
    end

    local new_fields = {}
    for i, f in ipairs(row_data) do
      -- 現在の列の左に空セルを挿入
      if i == col_idx then
        table.insert(new_fields, "  ")
      end
      table.insert(new_fields, f.text)
    end
    table.insert(new_lines, table.concat(new_fields, ","))
  end

  vim.api.nvim_buf_set_lines(main_buf, 0, -1, false, new_lines)
  metrics.compute_all(main_buf, parser)
  require("csvex.view").update_winbar()

  vim.schedule(function()
    local cur_lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
    local new_row_data = metrics.row_cache[cur_lnum]
    if new_row_data and new_row_data[col_idx] then
      vim.api.nvim_win_set_cursor(0, { cur_lnum + 1, math.max(0, new_row_data[col_idx].start - 1) })
    end
  end)
end

function M.insert_row_below()
  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  local row_data = require("csvex.metrics").row_cache[lnum]

  -- 現在の行の列数を取得（キャッシュがない場合は最低1列）
  local col_count = row_data and #row_data or 1

  -- 列数分の空セル "  " を用意してカンマで結合
  local empty_fields = {}
  for _ = 1, col_count do
    table.insert(empty_fields, "  ")
  end
  local new_line = table.concat(empty_fields, ",")

  local main_buf = vim.api.nvim_get_current_buf()

  -- 下の行に挿入
  vim.api.nvim_buf_set_lines(main_buf, lnum + 1, lnum + 1, false, { new_line })

  require("csvex.metrics").compute_all(main_buf, require("csvex.parser"))
  require("csvex.view").update_winbar()
  require("csvex.core").force_render(main_buf)

  vim.schedule(function()
    vim.api.nvim_win_set_cursor(0, { lnum + 2, 0 })
  end)
end

function M.insert_row_above()
  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  local row_data = require("csvex.metrics").row_cache[lnum]

  local col_count = row_data and #row_data or 1

  local empty_fields = {}
  for _ = 1, col_count do
    table.insert(empty_fields, "  ")
  end
  local new_line = table.concat(empty_fields, ",")

  local main_buf = vim.api.nvim_get_current_buf()

  -- 上の行に挿入
  vim.api.nvim_buf_set_lines(main_buf, lnum, lnum, false, { new_line })

  require("csvex.metrics").compute_all(main_buf, require("csvex.parser"))
  require("csvex.view").update_winbar()

  vim.schedule(function()
    vim.api.nvim_win_set_cursor(0, { lnum + 1, 0 })
  end)
end

return M
