return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections = opts.sections or {}
    opts.sections.lualine_x = {
      "filetype",
    }
    opts.sections.lualine_y = {}
    opts.sections.lualine_z = {
      "location",
    }
    return opts
  end,
}
