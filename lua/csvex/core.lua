local M = {}

local keymap = require("csvex.keymap")
local metrics = require("csvex.metrics")
local parser = require("csvex.parser")
local view = require("csvex.view")

local ns_id = vim.api.nvim_create_namespace("csvex_view")

local function force_render_current_view(bufnr)
  local winid = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_buf(winid) ~= bufnr then
    return
  end

  local toprow = vim.fn.line("w0")
  local botrow = vim.fn.line("w$")
  local leftcol = vim.fn.winsaveview().leftcol
  local start_row = math.max(0, toprow - 1)

  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  vim.wait(0)
  for lnum = start_row, botrow do
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, lnum, lnum + 1)

    local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1]
    if line then
      local fields = parser.parse_line(line)
      view.render_line(bufnr, lnum, fields, ns_id, metrics.max_width, leftcol)
    end
  end
end

M.force_render = force_render_current_view

function M.attach(bufnr)
  if vim.b[bufnr].csvex_attached then
    return
  end
  vim.b[bufnr].csvex_attached = true

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local padded_lines = {}
  local has_empty_cells = false

  for _, line in ipairs(lines) do
    local fields = parser.parse_line(line)
    local mapped_fields = {}
    for _, field in ipairs(fields) do
      if field.text == "" then
        table.insert(mapped_fields, "  ")
        has_empty_cells = true
      else
        table.insert(mapped_fields, field.text)
      end
    end
    table.insert(padded_lines, table.concat(mapped_fields, ","))
  end

  if has_empty_cells then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, padded_lines)
    vim.bo[bufnr].modified = false -- バッファ書き換えによる未保存状態をリセット
  end

  vim.api.nvim_buf_call(bufnr, function()
    keymap.setup_keys()
    vim.opt_local.virtualedit = "all"
    vim.opt_local.list = false
  end)

  vim.b[bufnr].miniindentscope_disable = true
  vim.b[bufnr].snacks_indent = false
  vim.b[bufnr].indent_blankline_enabled = false

  local ok, ibl = pcall(require, "ibl")
  if ok and type(ibl.setup_buffer) == "function" then
    pcall(ibl.setup_buffer, bufnr, { enabled = false })
  end

  require("csvex.config.sys_applier").apply_to_buffer(bufnr, require("csvex.config.defaults").sys)

  parser.normalize_buffer(bufnr)

  metrics.compute_all(bufnr, parser)

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
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end
        local current_line_idx = vim.fn.line(".")
        local cursor_winline = vim.fn.winline()

        if current_line_idx == 1 then
          local view_opt = vim.fn.winsaveview()
          if view_opt.topline > 1 or cursor_winline == 1 then
            vim.fn.winrestview({ topline = 1 })
            vim.cmd([[execute "normal! \<C-y>\<C-y>\<C-y>"]])
          end
        end
      end)
    end,
  })

  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = function(_, _, _, firstline, lastline, new_lastline)
      metrics.update_delta(bufnr, parser, firstline, lastline, new_lastline)

      if vim.api.nvim_get_current_buf() == bufnr then
        force_render_current_view(bufnr)
      end

      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
          view.update_winbar()
        end
      end)
    end,
  })

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = bufnr,
    callback = function(args)
      local filepath = args.match
      if filepath == "" then
        vim.notify("E32: No file name", vim.log.levels.ERROR)
        return
      end

      local clean_lines = {}
      local last_lnum = vim.api.nvim_buf_line_count(bufnr) - 1

      for lnum = 0, last_lnum do
        vim.api.nvim_buf_clear_namespace(bufnr, ns_id, lnum, lnum + 1)
        -- すでに計算済みのキャッシュを利用して重いパース処理をスキップ
        local fields = metrics.row_cache[lnum]

        -- 万が一キャッシュがない場合のみパースする
        if not fields then
          local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1] or ""
          fields = parser.parse_line(line)
        end

        local mapped_fields = {}
        for _, field in ipairs(fields) do
          local text = field.text

          if text:sub(1, 1) == '"' and text:sub(-1, -1) == '"' then
            text = text:sub(2, -2)
          end

          if text == "  " or text == "  " or text == "  " then
            table.insert(mapped_fields, "")
          else
            -- 修正: 処理後の text を挿入するように変更
            table.insert(mapped_fields, text)
          end
        end

        table.insert(clean_lines, table.concat(mapped_fields, ","))
      end

      local f, err = io.open(filepath, "w")
      if not f then
        vim.notify("CSV Save failed (io.open): " .. tostring(err), vim.log.levels.ERROR)
        return
      end

      local content = table.concat(clean_lines, "\n")
      if #clean_lines > 0 and clean_lines[#clean_lines] ~= "" then
        content = content .. "\n"
      end

      f:write(content)
      f:close()

      vim.bo[bufnr].modified = false
      vim.api.nvim_exec_autocmds("BufWritePost", { buffer = bufnr, modeline = false })

      vim.notify(
        string.format(
          '"%s" %dL, %dB written (Pure data format)',
          vim.fn.fnamemodify(filepath, ":t"),
          #clean_lines,
          #content
        ),
        vim.log.levels.INFO
      )
    end,
  })
end

return M
