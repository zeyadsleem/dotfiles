return {
  "mfussenegger/nvim-lint",
  opts = {
    linters_by_ft = {
      javascript = { "oxlint" },
      typescript = { "oxlint" },
      javascriptreact = { "oxlint" },
      typescriptreact = { "oxlint" },
    },
  },
  config = function(_, opts)
    local lint = require("lint")

    local function select_linter(ft)
      local has_eslint = vim.fn.executable("eslint") == 1

      if ft:match("javascript") or ft:match("typescript") then
        if has_eslint then
          return { "eslint" }
        else
          return opts.linters_by_ft[ft] or {}
        end
      end
      return opts.linters_by_ft[ft] or {}
    end

    lint.linters_by_ft = opts.linters_by_ft

    vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
      callback = function()
        local ft = vim.bo.filetype
        lint.linters_by_ft[ft] = select_linter(ft)
        lint.try_lint()
      end,
    })
  end,
}
