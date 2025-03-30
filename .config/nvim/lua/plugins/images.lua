return {
  {
    "3rd/image.nvim",
    event = "VeryLazy",
    config = function()
      require("image").setup({
        backend = "kitty",
        kitty_method = "normal",
        integrations = {
          markdown = {
            enabled = true,
            filetypes = { "markdown", "vimwiki" },
          },
        },
        max_height_window_percentage = 50,
      })
    end,
  },
}
