return {
  "folke/snacks.nvim",
  opts = {
    explorer = {
      enabled = true,
      hidden = true,
      ignored = true,
    },
    scroll = { enabled = false },
    picker = {
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
        },
        files = {
          hidden = true,
          ignored = true,
        },
        grep = {
          hidden = true,
          ignored = true,
        },
      },
      exclude = {
        "node_modules",
        "pnpm-lock.yaml",
        "package-lock.json",
        ".git",
        "target",
        "build",
        "dist",
        "out",
        "venv",
        "env",
        ".venv",
      },
    },
  },
}
