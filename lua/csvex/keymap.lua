local M = {}
local actions = require("csvex.actions")

function M.setup_keys()
  local opts = { buffer = true, silent = true }

  opts.desc = "Jump to next CSV cell"
  vim.keymap.set("n", "l", actions.jump_next_cell, opts)
  vim.keymap.set("n", "w", actions.jump_next_cell, opts)
  vim.keymap.set("n", "e", actions.jump_next_cell, opts)

  opts.desc = "Jump to previous CSV cell"
  vim.keymap.set("n", "h", actions.jump_prev_cell, opts)
  vim.keymap.set("n", "b", actions.jump_prev_cell, opts)

  opts.desc = "Jump to first CSV cell in row"
  vim.keymap.set("n", "0", actions.jump_first_cell_in_row, opts)
  vim.keymap.set("n", "^", actions.jump_first_cell_in_row, opts)

  opts.desc = "Jump to last CSV cell in row"
  vim.keymap.set("n", "$", actions.jump_last_cell_in_row, opts)

  opts.desc = "Jump to top-left CSV cell"
  vim.keymap.set("n", "gg", actions.jump_top_left_cell, opts)

  opts.desc = "Jump to bottom-left CSV cell"
  vim.keymap.set("n", "G", actions.jump_bottom_left_cell, opts)

  opts.desc = "Jump to CSV cell below"
  vim.keymap.set("n", "j", actions.jump_down_cell, opts)

  opts.desc = "Jump to CSV cell above"
  vim.keymap.set("n", "k", actions.jump_up_cell, opts)

  opts.nowait = false
  opts.desc = "Edit cell (prevents virtualedit space injection)"
  vim.keymap.set("n", "i", actions.edit_cell, opts)
  vim.keymap.set("n", "a", actions.edit_cell, opts)
  vim.keymap.set("n", "I", actions.edit_cell, opts)
  vim.keymap.set("n", "A", actions.edit_cell, opts)

  opts.desc = "Insert row below"
  opts.nowait = false
  vim.keymap.set("n", "o", actions.insert_row_below, opts)

  opts.desc = "Insert row above"
  vim.keymap.set("n", "O", actions.insert_row_above, opts)

  opts.desc = "Delete current column"
  vim.keymap.set("n", "dc", actions.delete_column, opts)

  opts.desc = "Insert column right"
  vim.keymap.set("n", "ic", actions.insert_column_right, opts)

  opts.desc = "Insert column left"
  vim.keymap.set("n", "iC", actions.insert_column_left, opts)
  -- enter -> edit
  opts.desc = "Edit current CSV cell"
  vim.keymap.set("n", "<CR>", actions.edit_cell, opts)

  opts.desc = "Clear current CSV cell"
  vim.keymap.set("n", "x", actions.clear_cell, opts)

  opts.desc = "Change current CSV cell"
  opts.nowait = true
  vim.keymap.set("n", "c", actions.change_cell, opts)
end

return M
