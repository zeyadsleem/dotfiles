local opt = vim.opt
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
vim.o.autoindent = true
vim.o.smartindent = true
opt.ambiwidth = "single"
opt.termbidi = true
opt.list = false
opt.listchars:append("space:⋅")
opt.listchars:append("eol:↴")
opt.termguicolors = true
opt.guifont = "DejaVu Sans Mono:h11"
opt.arabicshape = true
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"
opt.cmdheight = 0
vim.o.winborder = "rounded"

vim.cmd([[
  autocmd FileType * setlocal formatoptions-=c formatoptions-=o
]])
