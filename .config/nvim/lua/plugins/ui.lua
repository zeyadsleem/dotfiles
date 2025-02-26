return {
  -- خط العمود الافتراضي لتوجيه طول السطر
  {
    "lukas-reineke/virt-column.nvim",
    opts = {
      char = { "┆" },
      virtcolumn = "80",
      highlight = { "NonText" },
    },
  },

  -- تحسين واجهة الرسائل والأوامر (معطل افتراضيًا كما في إعداداتك)
  {
    "folke/noice.nvim",
    enabled = false,
    opts = {
      cmdline = {
        view = "cmdline_popup", -- واجهة أفضل للأوامر عند تفعيلها
      },
      messages = {
        view = "mini", -- عرض الرسائل بشكل مصغر
      },
    },
  },

  -- إظهار حالة LSP بشكل مرئي
  {
    "j-hui/fidget.nvim",
    opts = {
      notification = {
        window = {
          winblend = 0, -- بدون شفافية كما في إعداداتك السابقة
          border = "rounded",
        },
      },
      progress = {
        display = {
          done_icon = "✓", -- أيقونة أنيقة عند الانتهاء
        },
      },
    },
  },

  -- نظام الإشعارات المخصص
  {
    "rcarriga/nvim-notify",
    opts = {
      timeout = 500,
      render = "compact",
      max_height = function()
        return math.floor(vim.o.lines * 0.75)
      end,
      max_width = function()
        return math.floor(vim.o.columns * 0.25)
      end,
      on_open = function(win)
        vim.api.nvim_win_set_config(win, { zindex = 100 })
      end,
      stages = "fade", -- تأثير بسيط للظهور والاختفاء
      background_colour = "#1e1e2e", -- لون خلفية متناسق
    },
  },

  -- إدارة التبويبات
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        mode = "tabs",
        show_buffer_close_icons = false,
        show_close_icon = false,
        separator_style = "thin", -- فواصل أنيقة بين التبويبات
        color_icons = true, -- ألوان للأيقونات لتسهيل التمييز
        diagnostics = "nvim_lsp", -- إظهار تشخيصات LSP على التبويبات
        always_show_bufferline = false, -- إخفاء الشريط عندما يكون هناك ملف واحد فقط
      },
    },
  },

  -- إضافة شريط حالة أنيق (لم يكن في إعداداتك السابقة)
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme = "auto",
        component_separators = { left = "│", right = "│" },
        section_separators = { left = "", right = "" },
        globalstatus = true, -- شريط حالة موحد
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff" },
        lualine_c = { { "filename", path = 1 } }, -- إظهار المسار النسبي
        lualine_x = { "diagnostics", "encoding", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },

  -- دعم Git (لم يكن في إعداداتك السابقة)
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
      },
      current_line_blame = false, -- إظهار معلومات الـ blame في السطر الحالي
      current_line_blame_opts = {
        delay = 500,
      },
    },
  },
}
