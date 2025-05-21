vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.ambiwidth = "single"
vim.opt.termbidi = true

vim.opt.list = false
vim.opt.listchars:append("space:⋅")
vim.opt.listchars:append("eol:↴")

vim.opt.termguicolors = true
vim.opt.guifont = "DejaVu Sans Mono:h11"
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.o.winborder = "rounded"

vim.lsp.inlay_hint.enable(false)

-- Set to "intelephense" to use intelephense instead of phpactor.
vim.g.lazyvim_php_lsp = "intelephense"
