--- @class Icon
--- @field RESOURCES table<ResourcesIcon, string>
--- @field SPACES table<SpacesIcon, string>
--- @alias ResourcesIcon "CPU"
--- @alias SpacesIcon "DEFAULT"

--- @type Icon
local M = {
	RESOURCES = {
		-- These icons use SF Symbols from SF Display font so they will most likely not be visible in the editor
		CPU = "􀧓",
	},
	SPACES = {
		DEFAULT = "󰣆",
	},
}

return M
