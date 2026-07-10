return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        mypy = {
          enabled = true,
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = {
          "ruff_fix",
          "ruff_format",
        },
      },
    },
  },
}
