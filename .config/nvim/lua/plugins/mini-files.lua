local function current_dir()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return vim.uv.cwd()
  end
  return vim.fs.dirname(path)
end

return {
  "nvim-mini/mini.files",
  opts = {
    options = {
      use_as_default_explorer = true,
    },
  },
  keys = {
    {
      "<leader>fe",
      function()
        require("mini.files").open(current_dir(), true)
      end,
      desc = "Mini.files (current file dir)",
    },
    {
      "<leader>fE",
      function()
        require("mini.files").open(vim.uv.cwd(), true)
      end,
      desc = "Mini.files (cwd)",
    },
    { "<leader>e", "<leader>fe", desc = "Mini.files (current file dir)", remap = true },
    { "<leader>E", "<leader>fE", desc = "Mini.files (cwd)", remap = true },
  },
}
