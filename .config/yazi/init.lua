require("git"):setup()
require("smart-enter"):setup({ open_multi = true })

-- Don't load it inside neovim, `yazi.nvim` has its own border
if not os.getenv("NVIM") then
	require("full-border"):setup({ type = ui.Border.PLAIN })
end

-- https://yazi-rs.github.io/docs/tips#username-hostname-in-header
Header:children_add(function()
	if ya.target_family() ~= "unix" then
		return ""
	end
 return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("#9ccfd8")
end, 500, Header.LEFT)

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
