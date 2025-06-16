return {
  "folke/snacks.nvim",
  opts = {
    explorer = {
      sources = {
        files = {
          hidden = true,
          exclude = { "node_modules" },
        },
      },
    },
    picker = {
      sources = {
        files = {
          hidden = true,
          exclude = { "node_modules" },
        },
      },
    },
  },
}
