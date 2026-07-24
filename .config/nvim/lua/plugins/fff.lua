return {
  "dmtrKovalenko/fff.nvim",
  build = function()
    require("fff.download").download_or_build_binary()
  end,
  lazy = false,
  opts = {
    max_threads = 4,
    hidden = true,
    frecency = { enabled = true },
    git = { status_text_color = true },
    grep = {
      max_file_size = 10 * 1024 * 1024,
      smart_case = true,
      modes = { "plain", "regex", "fuzzy" },
    },
  },
  keys = {
    {
      "<space><space>",
      function()
        require("fff").find_files()
      end,
      desc = "Find Files (fff)",
    },
    {
      "<leader>ff",
      function()
        require("fff").find_files()
      end,
      desc = "Find Files (fff)",
    },
    {
      "<leader>fg",
      function()
        require("fff").live_grep()
      end,
      desc = "Live Grep (fff)",
    },
    {
      "<leader>fw",
      function()
        require("fff").live_grep_under_cursor()
      end,
      mode = { "n", "x" },
      desc = "Grep Word (fff)",
    },
    {
      "<leader>fz",
      function()
        require("fff").live_grep({ grep = { modes = { "fuzzy", "plain" } } })
      end,
      desc = "Fuzzy Grep (fff)",
    },
  },
}
