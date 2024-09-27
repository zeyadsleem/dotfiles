return {
  {
    "Mofiqul/vscode.nvim",
    priority = 1000,
    config = function()
      local c = require("vscode.colors").get_colors()
      require("vscode").setup({
        style = "dark",
        transparent = false,
        disable_nvimtree_bg = true,
        color_overrides = {
          vscLineNumber = "#FFFFFF",
        },
        group_overrides = {
          Identifier = { fg = c.vscLightBlue, bg = "NONE" },
        },
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
