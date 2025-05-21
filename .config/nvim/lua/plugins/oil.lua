return {
  "stevearc/oil.nvim",
  opts = {
    view_options = {
      show_hidden = true,
      is_hidden_file = function(name, bufnr)
        return name:match("^%.") ~= nil
      end,
      is_always_hidden = function(name, bufnr)
        return false
      end,
      natural_order = "fast",
      case_insensitive = false,
      sort = {
        { "type", "asc" },
        { "name", "asc" },
      },
    },

    float = {
      get_win_title = nil,
      preview_split = "right",
      override = function(conf)
        return conf
      end,
    },
  },
  vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" }),
}
