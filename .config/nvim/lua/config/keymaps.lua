-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set

-- Herdr owns Ctrl+Alt+H/J/K/L for pane movement, so bare Ctrl+H/J/K/L are free
-- for split navigation inside Neovim.
local function move_split(direction)
  if #vim.api.nvim_tabpage_list_wins(0) > 1 then
    vim.cmd("wincmd " .. direction)
  end
end

map("n", "<C-h>", function() move_split("h") end, { desc = "Go to left split" })
map("n", "<C-j>", function() move_split("j") end, { desc = "Go to below split" })
map("n", "<C-k>", function() move_split("k") end, { desc = "Go to above split" })
map("n", "<C-l>", function()
  vim.cmd("nohlsearch")
  vim.cmd("diffupdate")
  move_split("l")
end, { desc = "Clear search and go to right split" })

map("i", "jj", "<Esc>", { desc = "Exit insert mode" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
map(
  "n",
  "<leader>fd",
  "<cmd>lua os.remove(vim.api.nvim_buf_get_name(0))<CR><cmd>bd!<CR>",
  { desc = "Delete current file" }
)
