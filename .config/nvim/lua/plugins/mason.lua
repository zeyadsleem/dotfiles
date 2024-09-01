return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "eslint-lsp",
        "hadolint",
        "prettierd",
        "graphql-language-service-cli",
        "emmet-ls",
        "shfmt",
        "stylua",
        "selene",
        "shellcheck",
        "sql-formatter",
        "biome",
      },
    },
  },
}
