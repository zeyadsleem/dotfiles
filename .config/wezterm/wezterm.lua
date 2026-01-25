local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ============================================================================
-- Appearance & Font
-- ============================================================================
config.font = wezterm.font_with_fallback({
	"JetBrains Mono",
	"DejaVu Sans Mono",
})
config.font_size = 12.0
config.line_height = 0.9
config.cell_width = 0.9

-- Rendering Engine (OpenGL is more stable for Tmux redraws)
config.front_end = "OpenGL"
config.prefer_egl = true -- Force EGL for better Wayland performance
config.max_fps = 144 -- Smooth scrolling and animations
config.webgpu_power_preference = "HighPerformance" -- Use discrete GPU if available

-- ============================================================================
-- Custom Color Scheme (Dynamic)
-- ============================================================================
-- Load colors from external file managed by 'set-theme' script
-- We use the full path to ensure it loads even if wezterm starts from elsewhere
local colors_path = wezterm.config_dir .. "/colors.lua"
local success, theme_colors = pcall(dofile, colors_path)
if success then
	config.colors = theme_colors
else
	-- Fallback if file is missing
	config.color_scheme = "Rose Pine"
end

config.window_background_opacity = 0.90
config.window_decorations = "RESIZE"
config.enable_tab_bar = false
config.window_padding = { left = 5, right = 5, top = 1, bottom = 1 }
config.window_close_confirmation = "NeverPrompt"
config.default_cursor_style = "BlinkingBar"
config.audible_bell = "SystemBeep"

config.keys = {
	{ key = "c", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("Clipboard") },
	{ key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },
	{ key = "v", mods = "CTRL", action = wezterm.action.PasteFrom("Clipboard") },
	{ key = "+", mods = "CTRL", action = wezterm.action.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = wezterm.action.DecreaseFontSize },
	{ key = "0", mods = "CTRL", action = wezterm.action.ResetFontSize },
}

config.mouse_bindings = {
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "NONE",
		action = wezterm.action.OpenLinkAtMouseCursor,
	},
}

-- ============================================================================
-- Tmux Compatibility & Bidi
-- ============================================================================
-- Strict LeftToRight prevents the cursor jumping around during Tmux pane switches
config.bidi_enabled = true
config.bidi_direction = "LeftToRight"

-- Avoid treating Arabic as "Double Width" to prevent grid misalignment
config.allow_square_glyphs_to_overflow_width = "WhenFollowedBySpace"

-- ============================================================================
-- Multiplexing (Client-Server / Unix Domains)
-- ============================================================================
-- This enables foot-like performance by keeping a server in the background
config.unix_domains = {
	{
		name = "unix",
	},
}

-- Automatically connect to the unix domain on startup
config.default_gui_startup_args = { "connect", "unix" }

return config
