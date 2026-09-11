return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    if opts.inlay_hints then
      opts.inlay_hints.enabled = false
    else
      opts.inlay_hints = { enabled = false }
    end

    -- nil/nixfmt/statix are provided by nix (home-manager), not mason
    opts.servers = opts.servers or {}
    opts.servers.nil_ls = vim.tbl_extend("force", opts.servers.nil_ls or {}, { mason = false })

    -- يمنع الـ layout shift اللي بيحصل لما diagnostics تظهر/تختفي في insert mode
    -- opts.diagnostics = vim.tbl_deep_extend("force", opts.diagnostics or {}, {
    --   update_in_insert = true,
    --   virtual_text = false,
    --   severity_sort = true,
    -- })

    return opts
  end,
}
