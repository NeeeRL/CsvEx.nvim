vim.api.nvim_create_user_command("CsvexTest", function()
  require("csvex").setup()
end, {})
