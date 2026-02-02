local opt = vim.opt
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.clipboard = "unnamedplus"
opt.ambiwidth = "single"
opt.termbidi = true
opt.list = true
opt.termguicolors = true
opt.guifont = "DejaVu Sans Mono:h11"
opt.arabicshape = true
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"
vim.o.winborder = "rounded"

-- Explicitly configure clipboard for Wayland (Sway)
if vim.fn.executable("wl-copy") == 1 then
  vim.g.clipboard = {
    name = "wl-clipboard",
    copy = {
      ["+"] = { "wl-copy" },
      ["*"] = { "wl-copy" },
    },
    paste = {
      ["+"] = { "wl-paste", "--no-newline" },
      ["*"] = { "wl-paste", "--no-newline" },
    },
    cache_enabled = 1,
  }
end

vim.cmd([[
  autocmd FileType * setlocal formatoptions-=c formatoptions-=o
]])

vim.g.lazyvim_python_ruff = "ruff"
