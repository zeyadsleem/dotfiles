return {
  "mhartington/formatter.nvim",
  config = function()
    local util = require("formatter.util")

    require("formatter").setup({
      logging = false,
      filetype = {
        javascript = {
          function()
            if vim.fn.executable("prettier") == 1 then
              return {
                exe = "prettier",
                args = { "--stdin-filepath", util.escape_path(util.get_current_buffer_file_path()) },
                stdin = true,
              }
            else
              return {
                exe = "oxfmt",
                args = { "-" },
                stdin = true,
              }
            end
          end,
        },
        typescript = {
          function()
            if vim.fn.executable("prettier") == 1 then
              return {
                exe = "prettier",
                args = { "--stdin-filepath", util.escape_path(util.get_current_buffer_file_path()) },
                stdin = true,
              }
            else
              return {
                exe = "oxfmt",
                args = { "-" },
                stdin = true,
              }
            end
          end,
        },
      },
    })
  end,
}
