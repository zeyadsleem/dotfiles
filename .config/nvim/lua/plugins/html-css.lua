return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {

      -- HTML (supports modern specs)
      html = {
        filetypes = { "html", "templ" },
      },

      -- CSS / SCSS / PostCSS
      cssls = {
        settings = {
          css = {
            validate = true,
            lint = {
              unknownAtRules = "ignore", -- Tailwind / modern CSS
            },
          },
          scss = {
            validate = true,
          },
          less = {
            validate = true,
          },
        },
      },

      -- Tailwind (HTML / JSX / TSX / Astro)
      tailwindcss = {
        filetypes = {
          "html",
          "css",
          "scss",
          "javascriptreact",
          "typescriptreact",
          "astro",
        },
      },
    },
  },
}
