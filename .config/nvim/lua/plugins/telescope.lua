return {
  "nvim-telescope/telescope.nvim",

  opts = {
    defaults = {
      layout_strategy = "horizontal",
      layout_config = {
        preview_width = 0.65,
        horizontal = {
          size = {
            width = "95%",
            height = "95%",
          },
        },
      },
      sorting_strategy = "ascending",
      winblend = 0,

      pickers = {
        find_files = {
          theme = "dropdown",
        },
      },

      mappings = {
        i = {
          ["<C-u>"] = false,
          ["<C-d>"] = false,
          ["<C-j>"] = require("telescope.actions").move_selection_next,
          ["<C-k>"] = require("telescope.actions").move_selection_previous,
        },
      },
    },
  },
}
