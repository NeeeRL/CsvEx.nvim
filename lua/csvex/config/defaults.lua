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
  -- insert or normal
  initial_mode = "normal",
  insert_enter_to_save = false,
  -- bottom or top
  bar_position = "bottom",
}

return M
