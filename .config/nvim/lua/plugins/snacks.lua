return {
  "folke/snacks.nvim",

  opts = {
    explorer = {
      enabled = true,
    },

    picker = {
      enabled = true,

      sources = {
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
  },
}
