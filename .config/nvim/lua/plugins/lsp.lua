return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    if opts.inlay_hints then
      opts.inlay_hints.enabled = false
    else
      opts.inlay_hints = { enabled = false }
    end

    -- يمنع الـ layout shift اللي بيحصل لما diagnostics تظهر/تختفي في insert mode
    -- opts.diagnostics = vim.tbl_deep_extend("force", opts.diagnostics or {}, {
    --   update_in_insert = true,
    --   virtual_text = false,
    --   severity_sort = true,
    -- })

    return opts
  end,
}
