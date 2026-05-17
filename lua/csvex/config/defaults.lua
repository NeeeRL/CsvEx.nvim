local M = {}

-- 必須級な設定
M.sys = {
  conceallevel = 2,
  concealcursor = "nvic",
  separator_hl = "CsvexSeparator",
  number = false,
  relativenumber = false,
  signcolumn = "no",
  wrap = false,
  cursorline = true,
  virtualedit = "onemore",
}

M.user = {
  -- normal or insert
  initial_mode = "normal",
  -- true or false
  insert_enter_to_save = false,
  -- bottom or top
  bar_position = "bottom",
  -- true or false
  auto_attach = false,
}

return M
