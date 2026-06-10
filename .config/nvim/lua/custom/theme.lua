local c = {
  bg = nil,
  bg2 = "#1a1b26",
  fg = "#dcdcdc",
  fg2 = "#a0a0b0",
  red = "#ff5555",
  green = "#50fa7b",
  yellow = "#f1fa8c",
  blue = "#5294e2",
  purple = "#bd93f9",
  cyan = "#8be9fd",
  pink = "#ff79c6",
  orange = "#ffb86c",
  gray = "#6c6c7c",
}

local function hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

local function apply()
  -- Editor
  hl("Normal", { fg = c.fg, bg = c.bg })
  hl("NormalFloat", { bg = c.bg })
  hl("FloatBorder", { fg = c.blue, bg = c.bg })
  hl("Cursor", { fg = c.bg, bg = c.cyan })
  hl("CursorLine", { bg = c.bg })
  hl("CursorLineNr", { fg = c.cyan, bold = true })
  hl("LineNr", { fg = c.gray })
  hl("SignColumn", { bg = c.bg })
  hl("ColorColumn", { bg = c.bg })
  hl("Conceal", { fg = c.gray })
  hl("Visual", { bg = "#3b3b5c" })
  hl("VisualNOS", { bg = "#3b3b5c" })
  hl("MatchParen", { fg = c.cyan, bold = true, underline = true })
  hl("Search", { fg = c.bg, bg = c.yellow })
  hl("IncSearch", { fg = c.bg, bg = c.orange })
  hl("CurSearch", { fg = c.bg, bg = c.red })
  hl("Substitute", { fg = c.bg, bg = c.green })

  -- Split / Separators
  hl("WinSeparator", { fg = c.blue, bg = c.bg })
  hl("VertSplit", { fg = c.gray, bg = c.bg })
  hl("HorizSplit", { fg = c.gray, bg = c.bg })

  -- Statusline / Tabline
  hl("StatusLine", { fg = c.fg, bg = c.bg })
  hl("StatusLineNC", { fg = c.gray, bg = c.bg })
  hl("TabLine", { fg = c.fg2, bg = c.bg })
  hl("TabLineSel", { fg = c.bg, bg = c.blue, bold = true })
  hl("TabLineFill", { bg = c.bg })

  -- Title / Fold
  hl("Title", { fg = c.purple, bold = true })
  hl("Folded", { fg = c.gray, bg = c.bg })
  hl("FoldColumn", { fg = c.gray, bg = c.bg })

  -- Popup Menu
  hl("Pmenu", { fg = c.fg, bg = c.bg })
  hl("PmenuSel", { fg = c.bg, bg = c.blue, bold = true })
  hl("PmenuSbar", { bg = c.bg })
  hl("PmenuThumb", { bg = c.gray })

  -- Diagnostic
  hl("DiagnosticOk", { fg = c.green })
  hl("DiagnosticHint", { fg = c.cyan })
  hl("DiagnosticInfo", { fg = c.blue })
  hl("DiagnosticWarn", { fg = c.orange })
  hl("DiagnosticError", { fg = c.red })
  hl("DiagnosticUnderlineOk", { sp = c.green, underline = true })
  hl("DiagnosticUnderlineHint", { sp = c.cyan, underline = true })
  hl("DiagnosticUnderlineInfo", { sp = c.blue, underline = true })
  hl("DiagnosticUnderlineWarn", { sp = c.orange, underline = true })
  hl("DiagnosticUnderlineError", { sp = c.red, underline = true })
  hl("DiagnosticSignOk", { fg = c.green })
  hl("DiagnosticSignHint", { fg = c.cyan })
  hl("DiagnosticSignInfo", { fg = c.blue })
  hl("DiagnosticSignWarn", { fg = c.orange })
  hl("DiagnosticSignError", { fg = c.red })
  hl("DiagnosticFloatingOk", { fg = c.green })
  hl("DiagnosticFloatingHint", { fg = c.cyan })
  hl("DiagnosticFloatingInfo", { fg = c.blue })
  hl("DiagnosticFloatingWarn", { fg = c.orange })
  hl("DiagnosticFloatingError", { fg = c.red })

  -- LSP
  hl("LspReferenceText", { bg = "#3b3b5c" })
  hl("LspReferenceRead", { bg = "#3b3b5c" })
  hl("LspReferenceWrite", { bg = "#3b3b5c" })
  hl("LspInlayHint", { fg = c.gray, italic = true })
  hl("LspCodeLens", { fg = c.gray })
  hl("LspSignatureActiveParameter", { fg = c.cyan, bold = true })

  -- Syntax base
  hl("Comment", { fg = c.purple, italic = true })
  hl("Constant", { fg = c.yellow })
  hl("String", { fg = c.green })
  hl("Character", { fg = c.green })
  hl("Number", { fg = c.cyan })
  hl("Boolean", { fg = c.cyan })
  hl("Float", { fg = c.cyan })
  hl("Function", { fg = c.blue })
  hl("Identifier", { fg = c.fg })
  hl("Keyword", { fg = c.pink })
  hl("Statement", { fg = c.pink, bold = true })
  hl("Conditional", { fg = c.pink })
  hl("Repeat", { fg = c.pink })
  hl("Label", { fg = c.pink })
  hl("Operator", { fg = c.red })
  hl("Exception", { fg = c.red, bold = true })
  hl("Include", { fg = c.pink })
  hl("Define", { fg = c.pink })
  hl("Macro", { fg = c.orange })
  hl("PreCondit", { fg = c.orange })
  hl("PreProc", { fg = c.purple })
  hl("Type", { fg = c.orange })
  hl("StorageClass", { fg = c.orange })
  hl("Structure", { fg = c.orange })
  hl("Typedef", { fg = c.orange })
  hl("Special", { fg = c.cyan })
  hl("SpecialChar", { fg = c.cyan })
  hl("Tag", { fg = c.blue })
  hl("Delimiter", { fg = c.fg })
  hl("SpecialComment", { fg = c.purple, italic = true })
  hl("Debug", { fg = c.red })
  hl("Underlined", { underline = true })
  hl("Ignore", { fg = c.gray })
  hl("Error", { fg = c.red, bold = true })
  hl("Todo", { fg = c.bg, bg = c.yellow, bold = true })

  -- Diff
  hl("DiffAdd", { fg = c.green, bg = c.bg })
  hl("DiffChange", { fg = c.orange, bg = c.bg })
  hl("DiffDelete", { fg = c.red, bg = c.bg })
  hl("DiffText", { fg = c.blue, bg = c.bg })
  hl("diffAdded", { fg = c.green })
  hl("diffRemoved", { fg = c.red })
  hl("diffChanged", { fg = c.orange })

  -- Spelling
  hl("SpellBad", { sp = c.red, undercurl = true })
  hl("SpellCap", { sp = c.blue, undercurl = true })
  hl("SpellLocal", { sp = c.cyan, undercurl = true })
  hl("SpellRare", { sp = c.purple, undercurl = true })

  -- Treesitter
  hl("@comment", { fg = c.purple, italic = true })
  hl("@comment.error", { fg = c.red, bold = true })
  hl("@comment.warning", { fg = c.orange, bold = true })
  hl("@comment.todo", { fg = c.yellow, bold = true })
  hl("@comment.note", { fg = c.blue, bold = true })
  hl("@error", { fg = c.red, bold = true })
  hl("@none", {})
  hl("@preproc", { fg = c.purple })
  hl("@define", { fg = c.pink })

  hl("@keyword", { fg = c.pink })
  hl("@keyword.function", { fg = c.pink })
  hl("@keyword.operator", { fg = c.red })
  hl("@keyword.return", { fg = c.pink })
  hl("@keyword.repeat", { fg = c.pink })
  hl("@keyword.conditional", { fg = c.pink })
  hl("@keyword.exception", { fg = c.red, bold = true })
  hl("@keyword.import", { fg = c.pink })
  hl("@keyword.storage", { fg = c.orange })
  hl("@keyword.type", { fg = c.orange })
  hl("@keyword.modifier", { fg = c.pink })

  hl("@string", { fg = c.green })
  hl("@string.special", { fg = c.cyan })
  hl("@string.escape", { fg = c.cyan })
  hl("@string.regexp", { fg = c.cyan })
  hl("@string.documentation", { fg = c.green, italic = true })

  hl("@number", { fg = c.cyan })
  hl("@boolean", { fg = c.cyan })
  hl("@float", { fg = c.cyan })

  hl("@function", { fg = c.blue })
  hl("@function.builtin", { fg = c.cyan })
  hl("@function.call", { fg = c.blue })
  hl("@function.macro", { fg = c.orange })
  hl("@function.method", { fg = c.blue })
  hl("@function.method.call", { fg = c.blue })

  hl("@parameter", { fg = c.orange })
  hl("@parameter.reference", { fg = c.orange })
  hl("@method", { fg = c.blue })
  hl("@method.call", { fg = c.blue })
  hl("@field", { fg = c.fg })
  hl("@property", { fg = c.fg })

  hl("@constructor", { fg = c.orange })
  hl("@operator", { fg = c.red })
  hl("@type", { fg = c.orange })
  hl("@type.builtin", { fg = c.orange })
  hl("@type.definition", { fg = c.orange })
  hl("@type.qualifier", { fg = c.orange })

  hl("@variable", { fg = c.fg })
  hl("@variable.builtin", { fg = c.cyan })
  hl("@variable.member", { fg = c.fg })
  hl("@variable.parameter", { fg = c.orange })

  hl("@constant", { fg = c.yellow })
  hl("@constant.builtin", { fg = c.cyan })
  hl("@constant.macro", { fg = c.yellow })

  hl("@label", { fg = c.pink })
  hl("@namespace", { fg = c.purple })
  hl("@symbol", { fg = c.yellow })

  hl("@attribute", { fg = c.cyan })
  hl("@attribute.builtin", { fg = c.cyan })
  hl("@decorator", { fg = c.cyan })

  hl("@punctuation.delimiter", { fg = c.fg })
  hl("@punctuation.bracket", { fg = c.fg2 })
  hl("@punctuation.special", { fg = c.pink })

  hl("@tag", { fg = c.blue })
  hl("@tag.attribute", { fg = c.orange })
  hl("@tag.delimiter", { fg = c.gray })

  hl("@markup.heading", { fg = c.blue, bold = true })
  hl("@markup.italic", { italic = true })
  hl("@markup.bold", { bold = true })
  hl("@markup.strikethrough", { strikethrough = true })
  hl("@markup.underline", { underline = true })
  hl("@markup.link", { fg = c.blue, underline = true })
  hl("@markup.link.url", { fg = c.cyan, underline = true })
  hl("@markup.link.label", { fg = c.blue })
  hl("@markup.list", { fg = c.orange })
  hl("@markup.list.checked", { fg = c.green })
  hl("@markup.list.unchecked", { fg = c.gray })
  hl("@markup.raw", { fg = c.green })
  hl("@markup.quote", { fg = c.purple })
  hl("@markup.math", { fg = c.cyan })

  hl("@diff.plus", { fg = c.green })
  hl("@diff.minus", { fg = c.red })
  hl("@diff.delta", { fg = c.orange })

  hl("@exception", { fg = c.red, bold = true })

  vim.g.colors_name = "custom-flavor"
end

return { apply = apply }
