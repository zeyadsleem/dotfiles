local ignore_patterns = {
  "%.git/",
  "node_modules/",
  "venv/",
  "%.venv/",
  "%.pdm%-build/",
  "__pycache__",
  "%.DS_Store",
  "%.mypy_cache/",
  "%.pytest_cache/",
  "%.ruff_cache/",
  "package%-lock%.json",
  "yarn%.lock",
  "pnpm%-lock%.yaml",
}

return {
  "ibhagwan/fzf-lua",
  cmd = "FzfLua",
  opts = {
    winopts = {
      height = 0.85,
      width = 0.9,
      row = 0.3,
      col = 0.5,
      preview = {
        layout = "horizontal",
        horizontal = "right:55%",
        vertical = "down:45%",
        border = "border",
        title = false,
        hidden = "nohidden",
      },
      border = "rounded",
      fullscreen = false,
    },
    files = {
      prompt = "Files❯ ",
      cwd_prompt = false,
      fd_opts = "--hidden --no-ignore-vcs",
      file_ignore_patterns = ignore_patterns,
      actions = {
        ["default"] = require("fzf-lua").actions.file_edit_or_qf,
        ["alt-i"] = require("fzf-lua").actions.toggle_ignore,
        ["alt-h"] = require("fzf-lua").actions.toggle_hidden,
      },
    },
    grep = {
      prompt = "Rg❯ ",
      input_prompt = "Grep for❯ ",
      rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden --no-ignore-vcs",
      file_ignore_patterns = ignore_patterns,
    },
  },
}
