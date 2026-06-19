local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ============================================================================
-- Font Settings
-- ============================================================================
config.font = wezterm.font_with_fallback({
	{ family = "Maple Mono NF", weight = "Medium" },
	{ family = "DejaVu Sans Mono" },
	{ family = "Cairo", weight = "Regular" },
	{ family = "Noto Sans Arabic", weight = "Regular" },
	{ family = "Amiri", weight = "Regular" },
})
config.font_size = 11.3
config.line_height = 1.15

-- Rendering Engine & Stability
config.front_end = "OpenGL"
config.use_cap_height_to_scale_fallback_fonts = true
config.max_fps = 60
config.custom_block_glyphs = true
config.audible_bell = "Disabled"

-- Arabic & RTL Stabilization
config.bidi_enabled = true
config.bidi_direction = "LeftToRight"
config.unicode_version = 9
-- Prevent icons/glyphs from overflowing and causing ghost characters
config.allow_square_glyphs_to_overflow_width = "Never"
config.cell_width = 1.05

-- ============================================================================
-- Window Settings
-- ============================================================================
config.window_padding = {
	left = 3,
	right = 3,
	top = 3,
	bottom = 3,
}
config.window_background_opacity = 0.9
config.window_decorations = "NONE"
config.window_close_confirmation = "NeverPrompt"
config.initial_cols = 120
config.initial_rows = 35

-- ============================================================================
-- Color Scheme (Dynamic)
-- ============================================================================
local colors_path = wezterm.config_dir .. "/colors.lua"
local success, theme_colors = pcall(dofile, colors_path)
if success then
	config.colors = theme_colors
else
	-- Fallback to Orchis Dark values if colors.lua is missing
	config.colors = {
		foreground = "#dcdcdc",
		background = "#1e1e1e",
		cursor_bg = "#5294e2",
		cursor_fg = "#ffffff",
		selection_bg = "#5294e2",
		selection_fg = "#ffffff",
		ansi = {
			"#1e1e1e", -- black
			"#ff5555", -- red
			"#50fa7b", -- green
			"#f1fa8c", -- yellow
			"#5294e2", -- blue
			"#bd93f9", -- magenta
			"#8be9fd", -- cyan
			"#dcdcdc", -- white
		},
		brights = {
			"#3e3e3e", -- black
			"#ff6e6e", -- red
			"#69ff94", -- green
			"#ffffa5", -- yellow
			"#7aa5ff", -- blue
			"#d6acff", -- magenta
			"#a4ffff", -- cyan
			"#ffffff", -- white
		},
	}
end

-- Add tab bar colors to the config.colors (merging or setting if not present)
if not config.colors.tab_bar then
	config.colors.tab_bar = {
		background = config.colors.background or "#1e1e1e",
		active_tab = {
			bg_color = config.colors.cursor_bg or "#5294e2",
			fg_color = config.colors.cursor_fg or "#ffffff",
		},
		inactive_tab = {
			bg_color = config.colors.background or "#1e1e1e",
			fg_color = config.colors.foreground or "#dcdcdc",
		},
		inactive_tab_hover = {
			bg_color = (config.colors.brights and config.colors.brights[1]) or "#3e3e3e",
			fg_color = (config.colors.brights and config.colors.brights[8]) or "#ffffff",
		},
		new_tab = {
			bg_color = config.colors.background or "#1e1e1e",
			fg_color = config.colors.foreground or "#dcdcdc",
		},
		new_tab_hover = {
			bg_color = (config.colors.brights and config.colors.brights[1]) or "#3e3e3e",
			fg_color = (config.colors.brights and config.colors.brights[8]) or "#ffffff",
		},
	}
end

-- ============================================================================
-- Tab Bar Settings
-- ============================================================================
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true

-- ============================================================================
-- Scrollback & Mouse
-- ============================================================================
config.scrollback_lines = 10000
-- Note: mouse_hide_wait is not a top-level config field in recent WezTerm versions.
-- To hide the mouse when typing:
config.hide_mouse_cursor_when_typing = true

-- ============================================================================
-- Keyboard Shortcuts
-- ============================================================================
config.disable_default_key_bindings = true
local act = wezterm.action

-- ============================================================================
-- Helper Functions
-- ============================================================================
local function copy_or_interrupt(window, pane)
	local selection = window:get_selection_text_for_pane(pane)
	if selection == "" then
		window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
	else
		window:perform_action(act.CopyTo("Clipboard"), pane)
		window:perform_action(act.ClearSelection, pane)
	end
end

config.keys = {
	-- Functional
	{ key = "F5", mods = "CTRL|SHIFT", action = act.ReloadConfiguration },
	{ key = "F6", mods = "CTRL|SHIFT", action = act.ShowDebugOverlay },

	-- Copy/Paste
	{ key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
	{ key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
	{ key = "c", mods = "CTRL", action = wezterm.action_callback(copy_or_interrupt) },
	{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
	{ key = "Insert", mods = "SHIFT", action = act.PasteFrom("PrimarySelection") },

	-- Font size
	{ key = "=", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "+", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
	{ key = "0", mods = "CTRL", action = act.ResetFontSize },

	-- Scrolling
	{ key = "PageUp", mods = "SHIFT", action = act.ScrollByPage(-1) },
	{ key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(1) },
	{ key = "Home", mods = "CTRL|SHIFT", action = act.ScrollToTop },
	{ key = "End", mods = "CTRL|SHIFT", action = act.ScrollToBottom },

	-- Tabs
	{ key = "t", mods = "CTRL|SHIFT", action = act.SpawnTab("DefaultDomain") },
	{ key = "q", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
	{ key = ".", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(1) },
	{ key = ",", mods = "CTRL|SHIFT", action = act.ActivateTabRelative(-1) },

	-- Windows (Panes in WezTerm are like Kitty windows)
	{ key = "Enter", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "[", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Prev") },
	{ key = "]", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Next") },

	-- Miscellaneous
	{ key = "u", mods = "CTRL|SHIFT", action = act.CharSelect },
}

return config
