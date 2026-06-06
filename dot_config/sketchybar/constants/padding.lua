--- @class Padding
--- @field BAR table<PaddingSetting, integer>
--- @alias PaddingSetting "PADDING_LEFT" | "PADDING_RIGHT"

--- @type Padding
local M = {
	BAR = {
		PADDING_LEFT = 15,
		PADDING_RIGHT = 15,
	},
	DEFAULT = {
		PADDING_LEFT = 5,
		PADDING_RIGHT = 5,
	},
}

return M
