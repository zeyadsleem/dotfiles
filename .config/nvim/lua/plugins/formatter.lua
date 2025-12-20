return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  opts = {
    formatters_by_ft = {
      -- JS / TS (Biome first, Prettier fallback)
      javascript = { "biome", "prettier_js" },
      typescript = { "biome", "prettier_js" },
      javascriptreact = { "biome", "prettier_js" },
      typescriptreact = { "biome", "prettier_js" },

      -- Other languages
      lua = { "stylua" },
      python = { "black", "isort" },
      go = { "gofmt", "goimports" },
      rust = { "rustfmt" },
      sh = { "shfmt" },

      -- Markup / config (2 spaces)
      html = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },
      json = { "biome", "prettier" },
      jsonc = { "biome", "prettier" },
      yaml = { "prettier" },

      ["*"] = { "trim_whitespace", "trim_newlines" },
    },

    formatters = {
      -- Prettier fallback for JS/TS
      prettier_js = {
        command = "prettier",
        args = {
          "--stdin-filepath",
          "$FILENAME",
          "--tab-width",
          "4",
          "--single-quote",
          "--semi",
          "false",
        },
      },

      -- Prettier for markup/config
      prettier = {
        command = "prettier",
        args = {
          "--stdin-filepath",
          "$FILENAME",
          "--tab-width",
          "2",
        },
      },
    },
  },
}
