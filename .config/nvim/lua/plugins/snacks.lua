return {
  "folke/snacks.nvim",

  -- The explorer is replaced by mini.files; keep the picker itself.
  keys = {
    { "<leader>e", false },
    { "<leader>E", false },
    { "<leader>fe", false },
    { "<leader>fE", false },
  },

  opts = {
    explorer = {
      enabled = false,
    },

    picker = {
      enabled = true,

      sources = {
        files = {
          hidden = true, -- Show dotfiles by default
        },
        explorer = {
          hidden = true,
          ignored = true,

          exclude = {
            "node_modules",
            "pnpm-lock.yaml",
            "package-lock.json",
            "bun.lock",
            ".git",
            "target",
            "build",
            "dist",
            "out",
            "venv",
            "env",
            ".venv",
            "__pycache__",
            "*.pyc",
            ".mypy_cache",
            ".ruff_cache",
          },
        },
      },
    },

    scroll = {
      enabled = false,
    },

    dashboard = {
      preset = {
        header = require('custom.dashboard_art'),
      },
    },
  },
}
