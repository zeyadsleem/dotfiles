return {
  {
    "Mofiqul/vscode.nvim",
    priority = 1000,
    config = function()
      require("vscode").setup({
        style = "dark",
        transparent = true,
        disable_nvimtree_bg = true,
        extra_groups = {
          "CmpItemKindFunction",
          "CmpItemKindMethod",
          "CmpItemKindVariable",
          "CmpItemKindKeyword",
        },
      })
      vim.cmd([[colorscheme vscode]])
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "vscode",
    },
  },
}
