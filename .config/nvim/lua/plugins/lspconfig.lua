return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        phpactor = {
          cmd = { vim.fn.expand("~/.local/share/nvim/mason/bin/phpactor"), "language-server" },
          root_dir = require("lspconfig.util").root_pattern("composer.json", ".git", vim.fn.getcwd()),
          init_options = {
            ["language_server_worse_reflection.inlay_hints.enable"] = true,
            ["language_server_worse_reflection.inlay_hints.params"] = true,
            ["language_server_worse_reflection.inlay_hints.types"] = false,
            ["language_server_phpstan.enabled"] = true,
            ["language_server_psalm.enabled"] = false,
          },
          on_attach = function(client, bufnr)
            if client.server_capabilities.inlayHintProvider then
              vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
              vim.notify("Inlay Hints enabled for phpactor on buffer " .. bufnr, vim.log.levels.INFO)
            else
              vim.notify("phpactor does not support Inlay Hints", vim.log.levels.WARN)
            end
          end,
        },
        jsonls = {
          on_new_config = function(new_config)
            new_config.settings.json.schemas = new_config.settings.json.schemas or {}
            vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
          end,
          settings = {
            json = {
              format = { enable = true },
              validate = { enable = true },
            },
          },
        },
        dockerls = {},
        docker_compose_language_service = {},
      },
    },
  },
}
