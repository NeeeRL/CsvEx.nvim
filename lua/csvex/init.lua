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
  local config = require("csvex.config")
  config.setup(opts)
  setup_highlights(opts)

  local core = require("csvex.core")
  local cfg = config.get()

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "csv",
    callback = function(args)
      if cfg.auto_attach then
        core.attach(args.buf)
      end
    end,
  })

  if cfg.auto_attach and vim.bo.filetype == "csv" then
    core.attach(vim.api.nvim_get_current_buf())
  end
end

function M.get()
  return require("csvex.config").get()
end

return M
