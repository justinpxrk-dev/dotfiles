--- @class Icon
--- @field RESOURCES table<ResourcesIcon, string>
--- @field SPACES table<SpacesIcon, string>
--- @alias ResourcesIcon "CPU" | "GPU" | "RAM" | "SENSORS"
--- @alias SpacesIcon "DEFAULT"

--- @type Icon
local M = {
	RESOURCES = {
		-- SF Symbols (rendered by SF Pro; see constants/font.lua). These are
		-- private-use-area glyphs, so they will most likely not be visible in the
		-- editor. One leads each resource widget, in front of its Stats alias
		-- (see plugins/resources.lua).
		CPU = "􀧓",
		GPU = "􀢹",
		RAM = "􀧖",
		SENSORS = "􂬮",
	},
	SPACES = {
		DEFAULT = "󰣆",
	},
}

return M
