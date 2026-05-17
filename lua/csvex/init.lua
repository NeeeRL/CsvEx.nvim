local M = {}

local function setup_highlights(opts)
  opts = opts or {}
  local user_highlights = opts.highlights or {}

  vim.api.nvim_set_hl(0, "CsvexSeparator", { link = "FloatBorder", default = true })
  vim.api.nvim_set_hl(0, "CsvexBorder", { link = "FloatBorder", default = true })
  vim.api.nvim_set_hl(0, "CsvexFormulaBar", { link = "NormalFloat", default = true })

  for hl_name, hl_settings in pairs(user_highlights) do
    vim.api.nvim_set_hl(0, hl_name, hl_settings)
  end
end

function M.setup(opts)
  require("csvex.config").setup(opts)
  setup_highlights()
  local core = require("csvex.core")

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "csv",
    callback = function(args)
      core.attach(args.buf)
    end,
  })

  if vim.bo.filetype == "csv" then
    core.attach(vim.api.nvim_get_current_buf())
  end

  vim.api.nvim_create_user_command("CsvexTest", function()
    core.attach(vim.api.nvim_get_current_buf())
  end, {})
end

return M
