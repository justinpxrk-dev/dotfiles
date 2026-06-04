--- @class Theme
--- @field THEME ThemeMode
--- @field THEME_MODES table<ThemeMode, string>
local M = {}

--- @type table<ThemeMode, string>
--- @alias ThemeMode "DARK" | "LIGHT"
M.THEME_MODES = {
	DARK = "DARK",
	LIGHT = "LIGHT",
}

--- @type ThemeMode
M.THEME = M.THEME_MODES.LIGHT

function M.refresh()
	local f = io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")
	if f ~= nil then
		local is_dark_mode = (f:read("*a"):match("Dark") ~= nil)
		f:close()
		M.THEME = is_dark_mode and M.THEME_MODES.DARK or M.THEME_MODES.LIGHT
	end
end

--- Pack a "#RRGGBB" hex string into a sketchybar 0xAARRGGBB color integer.
--- @param hex string e.g. "#1e1e2e"
--- @param alpha integer? opacity byte 0x00-0xff (default 0xff, fully opaque)
--- @return integer color
function M.hex_to_color(hex, alpha)
	return ((alpha or 0xff) << 24) | tonumber(hex:sub(2), 16)
end

return M
