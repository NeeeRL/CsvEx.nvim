local M = {}

M.max_width = {}
M.row_cache = {}

function M.update_line(lnum, fields)
  M.row_cache[lnum] = fields

  for i, field in ipairs(fields) do
    local width = vim.api.nvim_strwidth(field.text)
    field.display_width = width

    local padded_width = width + 2

    if not M.max_width[i] or width > M.max_width[i] then
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

    M.row_cache[lnum] = fields

    for i, field in ipairs(fields) do
      local current_width = vim.api.nvim_strwidth(field.text)
      local padded_width = current_width + 2
      if not M.max_width[i] or current_width > M.max_width[i] then
        M.max_width[i] = padded_width
      end
    end
  end
end

return M
