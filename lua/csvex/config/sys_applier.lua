local M = {}

local saved_opts = {}

function M.apply_to_buffer(bufnr, sys_options)
  local group = vim.api.nvim_create_augroup("CsvexSysOptions_" .. bufnr, { clear = true })

  local function apply(winid)
    if not saved_opts[winid] then
      saved_opts[winid] = {
        conceallevel = vim.wo[winid].conceallevel,
        concealcursor = vim.wo[winid].concealcursor,
        number = vim.wo[winid].number,
        relativenumber = vim.wo[winid].relativenumber,
        signcolumn = vim.wo[winid].signcolumn,
        wrap = vim.wo[winid].wrap,
        cursorline = vim.wo[winid].cursorline,
        virtualedit = vim.wo[winid].virtualedit,
        winhighlight = vim.wo[winid].winhighlight,
      }
    end

    vim.wo[winid].conceallevel = sys_options.conceallevel
    vim.wo[winid].concealcursor = sys_options.concealcursor
    vim.wo[winid].number = sys_options.number
    vim.wo[winid].relativenumber = sys_options.relativenumber
    vim.wo[winid].signcolumn = sys_options.signcolumn
    vim.wo[winid].wrap = sys_options.wrap
    vim.wo[winid].cursorline = sys_options.cursorline
    vim.wo[winid].virtualedit = sys_options.virtualedit
    vim.wo[winid].winhighlight = sys_options.winhighlight
  end

  local function restore(winid)
    local opts = saved_opts[winid]
    if opts then
      vim.wo[winid].conceallevel = opts.conceallevel
      vim.wo[winid].concealcursor = opts.concealcursor
      vim.wo[winid].number = opts.number
      vim.wo[winid].relativenumber = opts.relativenumber
      vim.wo[winid].signcolumn = opts.signcolumn
      vim.wo[winid].wrap = opts.wrap
      vim.wo[winid].cursorline = opts.cursorline
      vim.wo[winid].virtualedit = opts.virtualedit
      vim.wo[winid].winhighlight = opts.winhighlight
      saved_opts[winid] = nil
    end
  end

  local current_win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_buf(current_win) == bufnr then
    apply(current_win)
  end

  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    buffer = bufnr,
    callback = function()
      apply(vim.api.nvim_get_current_win())
    end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    group = group,
    buffer = bufnr,
    callback = function()
      restore(vim.api.nvim_get_current_win())
    end,
  })
end

return M
