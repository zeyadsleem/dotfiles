local opt = vim.opt
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.clipboard = "unnamedplus"
opt.autoindent = true

opt.termguicolors = true
opt.termbidi = true
opt.arabicshape = true
opt.encoding = "utf-8"
vim.o.winborder = "rounded"
opt.fileencoding = "utf-8"
opt.conceallevel = 0
opt.concealcursor = ""
opt.signcolumn = "yes:2"

vim.keymap.set("i", "<CR>", function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  if col >= 1 and line:sub(col, col) == "{" and line:sub(col + 1, col + 1) == "}" then
    local base_indent = vim.fn.indent(row)
    local inner = base_indent + vim.bo.shiftwidth
    local before = line:sub(1, col - 1)
    local after = line:sub(col + 2)
    vim.api.nvim_buf_set_lines(0, row - 1, row, false, {
      before .. "{",
      string.rep(" ", inner),
      string.rep(" ", base_indent) .. "}" .. after,
    })
    vim.api.nvim_win_set_cursor(0, { row + 1, inner })
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
  end
end, { desc = "Expand braces on Enter" })

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "FileType" }, {
  callback = function()
    vim.wo.conceallevel = 0
    vim.wo.concealcursor = ""
  end,
  desc = "Force conceal off everywhere",
})

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    require("custom.theme").apply()
  end,
  desc = "Apply custom theme",
})
