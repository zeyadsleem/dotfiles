return {
  {
    "neovim/nvim-lspconfig",
    dependencies = { "nvim-telescope/telescope.nvim" },
    opts = {
      servers = {
        intelephense = {
          cmd = { "intelephense", "--stdio" },
          filetypes = { "php" },
          root_dir = function(fname)
            return require("lspconfig.util").root_pattern("composer.json", ".git")(fname) or vim.fn.getcwd()
          end,
          settings = {
            intelephense = {
              diagnostics = { enable = true },
              format = { enable = true },
              completion = { enable = true },
              telemetry = { enabled = false },
            },
          },
        },
      },
      setup = {
        intelephense = function(_, opts)
          vim.keymap.set("n", "<leader>ca", "<cmd>Telescope lsp_code_actions<CR>", {
            buffer = true,
            desc = "LSP: Code Action (Telescope)",
          })
          vim.keymap.set("v", "<leader>ca", "<cmd>Telescope lsp_code_actions<CR>", {
            buffer = true,
            desc = "LSP: Code Action (Visual, Telescope)",
          })
        end,
      },
    },
  },

  {
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      local nls = require("null-ls")
      opts.sources = opts.sources or {}
      table.insert(opts.sources, nls.builtins.formatting.phpcbf)
      table.insert(opts.sources, nls.builtins.diagnostics.phpcs)
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
}
