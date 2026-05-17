local M = {}

M.max_width = {}
M.row_cache = {}

function M.update_line(lnum, fields)
  M.row_cache[lnum] = fields

  for i, field in ipairs(fields) do
    local width = vim.api.nvim_strwidth(field.text)
    field.display_width = width

    local padded_width = width + 2

    if not M.max_width[i] or padded_width > M.max_width[i] then
      M.max_width[i] = padded_width
    end
  end
end

function M.compute_all(bufnr, parser)
  M.max_width = {}
  M.row_cache = {}

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for idx, line in ipairs(lines) do
    local lnum = idx - 1 -- ipairsは1始まりなので、0始まりに戻す
    local fields = parser.parse_line(line)
    M.update_line(lnum, fields)
  end
end

function M.update_delta(bufnr, parser, firstline, lastline, new_lastline)
  local diff = new_lastline - lastline

  if diff > 0 then
    local total_lines = vim.api.nvim_buf_line_count(bufnr)
    for i = total_lines - 1, new_lastline, -1 do
      M.row_cache[i] = M.row_cache[i - diff]
    end
  elseif diff < 0 then
    local total_lines = vim.api.nvim_buf_line_count(bufnr)
    for i = new_lastline, total_lines - 1 do
      M.row_cache[i] = M.row_cache[i - diff]
    end
    for i = total_lines, total_lines - diff - 1 do
      M.row_cache[i] = nil
    end
  end

  if firstline < new_lastline then
    local lines = vim.api.nvim_buf_get_lines(bufnr, firstline, new_lastline, false)
    for i, line in ipairs(lines) do
      local lnum = firstline + i - 1
      local fields = parser.parse_line(line)
      M.update_line(lnum, fields)
    end
  end
end

return M
