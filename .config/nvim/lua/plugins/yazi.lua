return {
  "mikavilpas/yazi.nvim",
  event = "VeryLazy",
  dependencies = { "folke/snacks.nvim", lazy = true },
  keys = {
    { ";f", mode = { "n", "v" }, "<cmd>Yazi<cr>", desc = "Open yazi" },
  }
}
