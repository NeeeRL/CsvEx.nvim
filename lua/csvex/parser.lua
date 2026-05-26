local M = {}

local str_byte = string.byte
local str_sub = string.sub

function M.parse_line(line, separator, quote_char)
  local sep = (separator or ","):byte()
  local quote = (quote_char or '"'):byte()
  local fields = {}

  local pos = 1
  local len = #line
  local field_start = 1

  while pos <= len do
    local b = str_byte(line, pos)

    if b == quote then
      pos = pos + 1
      while pos <= len do
        local b_inner = str_byte(line, pos)
        if b_inner == quote then
          if str_byte(line, pos + 1) == quote then
            pos = pos + 1
          else
            break
          end
        end
        pos = pos + 1
      end
      pos = pos + 1
    elseif b == sep then
      table.insert(fields, {
        text = str_sub(line, field_start, pos - 1),
        -- 1-indexedなのに注意
        start = field_start,
      })

      pos = pos + 1
      field_start = pos
    else
      pos = pos + 1
    end
  end

  table.insert(fields, {
    text = str_sub(line, field_start, len),
    start = field_start,
  })

  return fields
end

function M.normalize_buffer(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local max_cols = 1
  local parsed_rows = {}

  for i, line in ipairs(lines) do
    local fields = M.parse_line(line)
    parsed_rows[i] = fields
    if #fields > max_cols then
      max_cols = #fields
    end
  end

  local needs_update = false
  local new_lines = {}

  for i, fields in ipairs(parsed_rows) do
    local diff = max_cols - #fields
    if diff > 0 then
      needs_update = true
      local padding = string.rep(",  ", diff)
      new_lines[i] = lines[i] .. padding
    else
      new_lines[i] = lines[i]
    end
  end

  if needs_update then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
    require("csvex.metrics").compute_all(bufnr, M)
  end
end

return M
