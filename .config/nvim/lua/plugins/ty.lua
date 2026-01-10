return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Enable ty
        ty = {
          mason = false, -- Ty is typically installed via uv, not Mason
        },
        -- Disable the default pyright to avoid duplicate diagnostics
        pyright = { enabled = false },
        basedpyright = { enabled = false },
      },
    },
  },
}
