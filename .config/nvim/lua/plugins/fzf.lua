return {
  "ibhagwan/fzf-lua",
  cmd = "FzfLua",
  opts = function(_)
    local fzf = require("fzf-lua")
    local actions = fzf.actions

    return {
      files = {
        cwd_prompt = false,
        actions = {
          ["alt-i"] = { actions.toggle_ignore },
          ["alt-h"] = { actions.toggle_hidden },
        },
        file_ignore_patterns = { "node_modules", "venv", "%.venv", "%.pdm%-build" },
      },
      grep = {
        actions = {
          ["alt-i"] = { actions.toggle_ignore },
          ["alt-h"] = { actions.toggle_hidden },
        },
        rg_opts = "--hidden --glob=!node_modules/** --glob=!.venv/** --glob=!venv/** --glob=!.pdm-build/**",
      },
    }
  end,
}
