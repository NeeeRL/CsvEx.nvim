local M = {}
local actions = require("csvex.actions")

function M.setup_keys()
  local opts = { buffer = true, silent = true }

  opts.desc = "Jump to next CSV cell"
  vim.keymap.set("n", "l", actions.jump_next_cell, opts)

  opts.desc = "Jump to previous CSV cell"
  vim.keymap.set("n", "h", actions.jump_prev_cell, opts)

  opts.desc = "Jump to CSV cell below"
  vim.keymap.set("n", "j", actions.jump_down_cell, opts)

  opts.desc = "Jump to CSV cell above"
  vim.keymap.set("n", "k", actions.jump_up_cell, opts)

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
