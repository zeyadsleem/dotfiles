return {
  "ibhagwan/fzf-lua",
  cmd = "FzfLua",
  opts = {
    files = {
      prompt = "Files❯ ",
      cwd_prompt = false,
      previewer = "builtin",
      file_ignore_patterns = {
        "%.git/",
        "node_modules/",
        "venv/",
        "%.venv/",
        "%.pdm%-build/",
        "pycache/",
        "%.DS_Store",
        "%.mypy_cache/",
        "%.pytest_cache/",
        "%.ruff_cache/",
      },
      actions = {
        ["default"] = require("fzf-lua").actions.file_edit_or_qf,
        ["alt-i"] = require("fzf-lua").actions.toggle_ignore,
        ["alt-h"] = require("fzf-lua").actions.toggle_hidden,
      },
      fd_opts = "--hidden --no-ignore-vcs",
    },
    grep = {
      rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden",
      prompt = "Rg❯ ",
      input_prompt = "Grep For❯ ",
      file_ignore_patterns = {
        "%.git/",
        "node_modules/",
        "venv/",
        "%.venv/",
        "%.pdm%-build/",
        "pycache/",
        "%.DS_Store",
        "%.mypy_cache/",
        "%.pytest_cache/",
        "%.ruff_cache/",
      },
      actions = {
        ["default"] = require("fzf-lua").actions.file_edit_or_qf,
      },
    },
  },
}
