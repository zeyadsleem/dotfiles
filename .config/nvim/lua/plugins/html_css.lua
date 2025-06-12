return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        html = {},
        cssls = {},
        tailwindcss = {},
        css_variables = {},
        cssmodules_ls = {},
      },
    },
  },
  {
    "roobert/tailwindcss-colorizer-cmp.nvim",
    event = "InsertEnter",
    config = function()
      require("tailwindcss-colorizer-cmp").setup()
    end,
    dependencies = { "hrsh7th/nvim-cmp" },
  },
  {
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup({
        "html",
        "css",
        "javascript",
        "typescript",
        "vue",
        "lua",
        "scss",
        "sass",
      }, { tailwind = true })
    end,
  },
}
