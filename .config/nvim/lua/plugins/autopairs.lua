return {
  "windwp/nvim-autopairs",
  config = function()
    require("nvim-autopairs").setup({
      check_ts = true,
      enable_check_bracket_line = true,
    })

    local npairs = require("nvim-autopairs")
    local Rule = require("nvim-autopairs.rule")
    local ts_conds = require("nvim-autopairs.ts-conds")

    npairs.add_rules({
      Rule("<", ">", "html")
        :with_pair(ts_conds.is_ts_node({ "element" }))
        :with_move(function(opts)
          return opts.prev_char:match(".%>") ~= nil
        end)
        :use_key("<CR>"),
    })
  end,
}
