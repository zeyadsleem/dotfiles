local opt = vim.opt

opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true

opt.ambiwidth = "single"
opt.termbidi = true
opt.list = false
opt.listchars:append("space:⋅")
opt.listchars:append("eol:↴")
opt.termguicolors = true
opt.guifont = "DejaVu Sans Mono:h11"
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"
opt.cmdheight = 0
vim.o.winborder = "rounded"
vim.g.lazyvim_php_lsp = "intelephense"
