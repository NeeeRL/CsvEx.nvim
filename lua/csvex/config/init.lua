local M = {}
local defaults = require("csvex.config.defaults")

local current_user_options = vim.deepcopy(defaults.user)

function M.setup(opts)
  current_user_options = vim.tbl_deep_extend("force", defaults.user, opts or {})
end

function M.get()
  return current_user_options
end

return M
