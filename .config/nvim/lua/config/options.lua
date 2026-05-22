local opt = vim.opt
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.clipboard = "unnamedplus"

opt.list = true
opt.termguicolors = true
opt.guifont = "DejaVu Sans Mono:h11"
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"
vim.o.winborder = "rounded"
opt.conceallevel = 0

-- يثبت عرض signcolumn عشان مايحصلش layout shift لما diagnostics تظهر/تختفي
opt.signcolumn = "yes:2"
