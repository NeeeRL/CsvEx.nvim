if vim.g.loaded_csvex_plugin then
  return
end
vim.g.loaded_csvex_plugin = true

vim.api.nvim_create_user_command("CsvexAttach", function()
  local core = require("csvex.core")

  if vim.bo.filetype == "csv" then
    core.attach(vim.api.nvim_get_current_buf())
  else
    vim.notify("Not a CSV file", vim.log.levels.WARN)
  end
end, {})
