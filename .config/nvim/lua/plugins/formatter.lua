return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  opts = {
    formatters_by_ft = {
      javascript = { "biome", "prettier" },
      typescript = { "biome", "prettier" },
      javascriptreact = { "biome", "prettier" },
      typescriptreact = { "biome", "prettier" },
      json = { "biome", "prettier" },
      jsonc = { "biome", "prettier" },
      css = { "biome", "prettier" },
      scss = { "prettier" },
      html = { "prettier" },
      yaml = { "prettier" },
      markdown = { "prettier" },
      lua = { "stylua" },
      python = { "black", "isort" },
      go = { "gofmt", "goimports" },
      rust = { "rustfmt" },
      sh = { "shfmt" },
      ["*"] = { "trim_whitespace", "trim_newlines" },
    },
    formatters = {
      biome = {
        prepend_args = function(self, ctx)
          local config_files = { "biome.json", "biome.jsonc" }
          local cwd = ctx.dirname or vim.fn.getcwd()

          for _, config_file in ipairs(config_files) do
            local config_path = vim.fn.findfile(config_file, cwd .. ";")
            if config_path ~= "" then
              return {}
            end
          end

          return {
            "--indent-style=2",
            "--quote-style=single",
            "--line-width=120",
          }
        end,
        condition = function(self, ctx)
          local cwd = ctx.dirname or vim.fn.getcwd()
          return vim.fn.findfile("biome.json", cwd .. ";") ~= "" or vim.fn.findfile("biome.jsonc", cwd .. ";") ~= ""
        end,
      },
      prettier = {
        prepend_args = function(self, ctx)
          local config_files = {
            ".prettierrc",
            ".prettierrc.json",
            ".prettierrc.js",
            ".prettierrc.cjs",
            "prettier.config.js",
            "prettier.config.cjs",
            ".prettierrc.yaml",
            ".prettierrc.yml",
          }

          local cwd = ctx.dirname or vim.fn.getcwd()

          if vim.fn.findfile("biome.json", cwd .. ";") ~= "" or vim.fn.findfile("biome.jsonc", cwd .. ";") ~= "" then
            return nil
          end

          for _, config_file in ipairs(config_files) do
            local config_path = vim.fn.findfile(config_file, cwd .. ";")
            if config_path ~= "" then
              return {}
            end
          end

          local package_json = vim.fn.findfile("package.json", cwd .. ";")
          if package_json ~= "" then
            local ok, data = pcall(vim.fn.json_decode, vim.fn.readfile(package_json))
            if ok and data.prettier then
              return {}
            end
          end

          return {
            "--tab-width",
            "4",
            "--single-quote",
            "true",
            "--trailing-comma",
            "es5",
            "--arrow-parens",
            "avoid",
            "--print-width",
            "120",
            "--semi",
            "false",
          }
        end,
        condition = function(self, ctx)
          local cwd = ctx.dirname or vim.fn.getcwd()
          return vim.fn.findfile("biome.json", cwd .. ";") == "" and vim.fn.findfile("biome.jsonc", cwd .. ";") == ""
        end,
      },
    },
  },
}
