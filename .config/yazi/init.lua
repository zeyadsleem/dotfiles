require("git"):setup()
require("smart-enter"):setup({ open_multi = true })

-- Don't load it inside neovim, `yazi.nvim` has its own border
if not os.getenv("NVIM") then
	require("full-border"):setup({ type = ui.Border.PLAIN })
end

-- https://yazi-rs.github.io/docs/tips#username-hostname-in-header
-- Anchor to the RIGHT with a low priority (2000) so it sits *before*
-- the default file counter on the far right, never crossing the
-- left pane border regardless of how long the hostname is.
Header:children_add(function()
	if ya.target_family() ~= "unix" then
		return ""
	end
	local host = ya.host_name():match("^([^-]+)") or ya.host_name()
	return ui.Span(ya.user_name() .. "@" .. host .. ":"):fg("#9ccfd8")
end, 2000, Header.RIGHT)

---@return unknown
-- https://yazi-rs.github.io/docs/tips#show-symlink-in-status-bar
function Status:name()
	local h = cx.active.current.hovered
	if not h then
		return ui.Span("")
	end

	local linked = ""
	if h.link_to ~= nil then
		linked = " -> " .. tostring(h.link_to)
	end
	return ui.Span(" " .. h.name .. linked)
end

-- https://yazi-rs.github.io/docs/tips#show-usergroup-of-files-in-status-bar
function Status:owner()
	local h = cx.active.current.hovered
	if h == nil or ya.target_family() ~= "unix" then
		return ui.Line({})
	end

	return ui.Line {
		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
		ui.Span(":"),
		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
		ui.Span(" "),
	}
end

function Entity:icon()
	local icon = self._file:icon()

	if not icon then
		return ui.Line("")
	elseif self._file.is_hovered then
		return ui.Line(icon.text .. "  ")
	else
		return ui.Line(icon.text .. "  "):style(icon.style)
	end
end
