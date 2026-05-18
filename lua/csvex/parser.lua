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

return M
