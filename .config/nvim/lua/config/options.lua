local opt = vim.opt
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.clipboard = "unnamedplus"

local function get_wayland_display()
  if vim.env.WAYLAND_DISPLAY then
    return vim.env.WAYLAND_DISPLAY
  end
  local uid = (vim.uv or vim.loop).getuid()
  local handle = io.popen("ls /run/user/" .. uid .. "/wayland-* 2>/dev/null | grep -v '.lock' | head -n 1")
  local result = handle:read("*a")
  if handle then handle:close() end
  if result ~= "" then
    return result:match("wayland%-%d+")
  end
  return "wayland-0"
end

local wdisplay = get_wayland_display()

vim.g.clipboard = {
  name = 'wl-utils',
  copy = {
    ['+'] = 'env WAYLAND_DISPLAY=' .. wdisplay .. ' wl-copy',
    ['*'] = 'env WAYLAND_DISPLAY=' .. wdisplay .. ' wl-copy',
  },
  paste = {
    ['+'] = 'env WAYLAND_DISPLAY=' .. wdisplay .. ' wl-paste --no-newline',
    ['*'] = 'env WAYLAND_DISPLAY=' .. wdisplay .. ' wl-paste --no-newline',
  },
  cache_enabled = 1,
}

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
