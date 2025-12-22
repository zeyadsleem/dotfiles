local opt = vim.opt
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.ambiwidth = "single"
opt.termbidi = true
opt.list = false

vim.cmd([[
  autocmd FileType * setlocal formatoptions-=c formatoptions-=o
]])
