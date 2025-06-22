local wezterm = require 'wezterm'

local config = {}

config.font_size = 11.8
config.line_height = 1.2
config.font = wezterm.font_with_fallback {
	{ family = 'JetBrainsMono Nerd Font' },
	{ family = 'DejaVu Sans Mono' },
	{ family = 'Symbols Nerd Font Mono' },
}

config.colors = {
	background = '#1E1E1E',
	foreground = '#D4D4D4',
	cursor_bg = '#FFFFFF',
	selection_bg = '#264F78',
	selection_fg = '#1E1E1E',
	ansi = {
		'#1E1E1E',
		'#F44747',
		'#608B4E',
		'#DCDCAA',
		'#569CD6',
		'#C678DD',
		'#56B6C2',
		'#D4D4D4',
	},
	brights = {
		'#808080',
		'#F44747',
		'#608B4E',
		'#DCDCAA',
		'#569CD6',
		'#C678DD',
		'#56B6C2',
		'#FFFFFF',
	},
}

config.window_padding = { left = 10, right = 10, top = 1, bottom = 1 }
config.cursor_blink_rate = 0
config.bidi_enabled = true
config.scrollback_lines = 10000
config.hide_tab_bar_if_only_one_tab = true

return config
