-- This file is automatically loaded by plugins.core
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- LazyVim auto format
vim.g.autoformat = true

-- ... (rest of the existing configuration)

-- Fix markdown indentation settings
vim.g.markdown_recommended_style = 0

-- Enhanced Arabic language support
vim.opt.termbidi = true
vim.opt.arabicshape = true
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.ambiwidth = "single"

-- Set font with Arabic support (adjust as needed)
vim.opt.guifont = "DejaVu Sans Mono:h11"

-- Ensure timeoutlen is set to a reasonable value
vim.opt.timeoutlen = 300

-- Function to set up Arabic text rendering
local function setup_arabic_rendering()
  vim.opt.rightleft = false
  vim.opt.rightleftcmd = "search"
  vim.wo.foldcolumn = "1"
  vim.wo.signcolumn = "yes"
  vim.opt.listchars = "tab:  ,trail:·,extends:◣,precedes:◢,nbsp:○"
end

-- Call the setup function
setup_arabic_rendering()

-- Automatically detect and set up Arabic file type
vim.cmd([[
  augroup ArabicBuffer
    autocmd!
    autocmd BufRead,BufNewFile *.ar setlocal filetype=arabic
    autocmd FileType arabic setlocal rightleft
  augroup END
]])
