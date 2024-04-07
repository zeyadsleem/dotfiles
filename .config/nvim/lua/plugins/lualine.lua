return {
  "nvim-lualine/lualine.nvim",

  opts = {
    options = {
      icons_enabled = false,
      component_separators = "|",
      section_separators = "",
    },
    sections = {
      lualine_x = {
        {
          color = { fg = "#ff9e64" },
        },
      },

      -- lualine_a = {
      --   {
      --     "buffers",
      --   },
      -- },
    },
  },
}
