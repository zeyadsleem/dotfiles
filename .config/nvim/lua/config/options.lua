-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- trern it on when you need to remove underline border
-- vim.opt.cmdheight = 0

-- Add any additional options here
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

vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- add custom color to inlay hints
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#a0a0a0", force = true })
  end,
})
vim.lsp.inlay_hint.enable(true)
