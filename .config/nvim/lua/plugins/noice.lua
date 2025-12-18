return {
  "folke/noice.nvim",
  opts = {
    presets = {
      lsp_doc_border = true,
    },
    lsp = {
      hover = {
        silent = true,
      },
    },
    routes = {
      {
        filter = {
          event = "notify",
          find = "No information available",
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "lsp",
          kind = "message",
          find = "eslint",
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "notify",
          find = "eslint",
        },
        opts = { skip = true },
      },
    },
  },
}
