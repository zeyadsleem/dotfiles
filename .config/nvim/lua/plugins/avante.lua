return {
  {
    "yetone/avante.nvim",
    opts = {
      provider = "openai",
      providers = {
        openai = {
          endpoint = "https://api.openai.com/v1",
          model = "gpt-4o",
          timeout = 30000,
          extra_request_body = {
            temperature = 0,
            max_tokens = 4096,
          },
        },
      },
    },
    config = function(_, opts)
      -- Check for OPENAI_BASE_URL environment variable
      local base_url = os.getenv("OPENAI_BASE_URL")
      if base_url then
        opts.providers.openai.endpoint = base_url
      end

      require("avante").setup(opts)
    end,
  },
}
