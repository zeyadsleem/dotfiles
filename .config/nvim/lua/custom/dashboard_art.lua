-- Header art + random quote for the snacks.dashboard.
-- Art from https://github.com/ahmedelgabri/dotfiles (config/nvim/lua/_/dashboard.lua),
-- originally via https://github.com/NvChad/NvChad/discussions/2755#discussioncomment-8960250

---@type string[]
local header = {
	'           ▄ ▄                   ',
	'       ▄   ▄▄▄     ▄ ▄▄▄ ▄ ▄     ',
	'       █ ▄ █▄█ ▄▄▄ █ █▄█ █ █     ',
	'    ▄▄ █▄█▄▄▄█ █▄█▄█▄▄█▄▄█ █     ',
	'  ▄ █▄▄█ ▄ ▄▄ ▄█ ▄▄▄▄▄▄▄▄▄▄▄▄▄▄  ',
	'  █▄▄▄▄ ▄▄▄ █ ▄ ▄▄▄ ▄ ▄▄▄ ▄ ▄ █ ▄',
	'▄ █ █▄█ █▄█ █ █ █▄█ █ █▄█ ▄▄▄ █ █',
	'█▄█ ▄ █▄▄█▄▄█ █ ▄▄█ █ ▄ █ █▄█▄█ █',
	'    █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█ █▄█▄▄▄█    ',
}

local lines = {}

for _, line in ipairs(header) do
	table.insert(lines, line)
end

-- Snacks expects the header as one multi-line string (not a table).
return table.concat(lines, '\n')
