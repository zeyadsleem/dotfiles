local opt = vim.opt
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.ambiwidth = "single"
opt.termbidi = true
opt.list = true
opt.termguicolors = true
opt.guifont = "DejaVu Sans Mono:h11"
opt.arabicshape = true
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"
vim.o.winborder = "rounded"

vim.cmd([[
  autocmd FileType * setlocal formatoptions-=c formatoptions-=o
]])

vim.g.lazyvim_python_ruff = "ruff"
