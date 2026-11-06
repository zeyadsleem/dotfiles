return {
  {
    "nickjvandyke/opencode.nvim",
    event = "VeryLazy", -- Defer off the startup path; OpenCode is only needed on demand.

    config = function()
      -- This plugin has no `setup()`: its options are read from `vim.g.opencode_opts`
      -- when `opencode.config` is first required. An empty table accepts the defaults
      -- defined in `lua/opencode/config.lua`.
      ---@type opencode.Opts
      vim.g.opencode_opts = {}

      local opencode = require("opencode")
      local keymap = vim.keymap.set

      -- `@this` resolves to a `file:line` location for the selection (or the cursor
      -- when there is no range), so every prompt carries the file OpenCode cannot see.
      keymap({ "n", "v" }, "<leader>oa", function()
        opencode.ask("@this: ")
      end, { desc = "OpenCode: Ask" })

      keymap({ "n", "v" }, "<leader>os", function()
        opencode.select()
      end, { desc = "OpenCode: Select Action" })

      -- `prompt()` takes a string and resolves `@` placeholders before sending it.
      -- `@this` becomes a `file:line` location for the selection (or the cursor when
      -- there is no range); `@diagnostics` becomes the buffer's diagnostics, or only
      -- those overlapping the selection. OpenCode then reads that context itself.

      keymap({ "n", "v" }, "<leader>oe", function()
        opencode.prompt("Explain @this and its context")
      end, { desc = "OpenCode: Explain Code" })

      keymap("n", "<leader>of", function()
        opencode.prompt("Fix @diagnostics")
      end, { desc = "OpenCode: Fix Diagnostics" })

      -- The TUI in this split attaches to the same background service as the OpenCode
      -- session in Herdr (discovered via `~/.local/state/opencode/service.json`).
      keymap("n", "<leader>oo", function()
        require("snacks.terminal").toggle("opencode", {
          win = { position = "right", width = 0.4, enter = true },
        })
      end, { desc = "OpenCode: Toggle Sidebar" })

      -- OpenCode runs in its own Herdr session, so its activity is invisible from here.
      -- These notifications surface the parts worth interrupting for; the statusline
      -- component in `plugins/lualine.lua` shows the continuous state.
      local group = vim.api.nvim_create_augroup("OpencodeNotify", { clear = true })
      local running = false

      local function notify(message, level)
        vim.notify(message, level, { title = "OpenCode" })
      end

      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "OpencodeEvent:*",
        callback = function(args)
          local event = args.data.event

          if event.type == "file.edited" then
            notify("Edited " .. vim.fn.fnamemodify(event.data.file, ":."))
          elseif event.type == "session.status" then
            local status = event.data and event.data.status
            local kind = status and status.type

            if kind == "busy" or kind == "retry" then
              running = true
            elseif kind == "idle" and running then
              running = false
              notify("Finished")
            end
          elseif event.type == "session.execution.failed" then
            running = false
            notify("Execution failed", vim.log.levels.ERROR)
          end
        end,
      })
    end,
  },
}
