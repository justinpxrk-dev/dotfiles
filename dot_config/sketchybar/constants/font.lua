--- @class Font
--- @field DEFAULT table<DefaultFontOption, FontSettings>
--- @alias DefaultFontOption "BOLD_LABEL" | "ICON" | "LABEL" | "SPACES_ICON"
--- @alias FontSettings table<FontSetting, string | number>
--- @alias FontSetting "family" | "style" | "size"

--- @type Font
local M = {
	DEFAULT = {
		BOLD_LABEL = {
			family = "SF Pro",
			style = "Bold",
			size = 13.0,
		},
		ICON = {
			family = "SF Pro",
			style = "Regular",
			size = 13.0,
		},
		LABEL = {
			family = "SF Pro",
			style = "Regular",
			size = 13.0,
		},
		SPACES_ICON = {
			family = "sketchybar-app-font",
			style = "Regular",
			size = 20.0,
		},
	},
}

return M
