return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  opts = {
    formatters_by_ft = {
      -- JS / TS
      javascript = { "biome" },
      typescript = { "biome" },
      javascriptreact = { "biome" },
      typescriptreact = { "biome" },

      -- Web
      html = { "biome" },
      css = { "biome" },
      scss = { "biome" },
      yaml = { "biome" },

      -- JSON / Config
      json = { "biome" },
      jsonc = { "biome" },

      -- Other languages
      lua = { "stylua" },
      python = { "black", "isort" },
      go = { "gofmt", "goimports" },
      rust = { "rustfmt" },
      sh = { "shfmt" },

      -- misc
      ["*"] = { "trim_whitespace", "trim_newlines" },
    },
  },
}
