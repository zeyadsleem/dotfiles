return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = {
    options = {
      theme = "auto",
      globalstatus = true,
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", "diff", "diagnostics" },
      lualine_c = { { "filename", path = 1 } },
      lualine_x = { "filetype" },
      lualine_y = { "progress" },
      lualine_z = {
        {
          -- Live OpenCode state (idle / busy / error) plus the connected server.
          -- Hidden until the plugin is loaded, so `require` never touches the
          -- runtimepath of a plugin that has not been loaded yet.
          function()
            return require("opencode").statusline()
          end,
          cond = function()
            return package.loaded["opencode"] ~= nil
          end,
        },
        "location",
      },
    },
  },
}
