local opt = vim.opt
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.clipboard = "unnamedplus"

opt.termguicolors = true
opt.encoding = "utf-8"
vim.o.winborder = "rounded"
opt.fileencoding = "utf-8"
opt.conceallevel = 0
opt.concealcursor = ""
opt.signcolumn = "yes:2"

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "FileType" }, {
  callback = function()
    vim.wo.conceallevel = 0
    vim.wo.concealcursor = ""
  end,
  desc = "Force conceal off everywhere",
})

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    require("custom.theme").apply()
  end,
  desc = "Apply custom theme",
})
