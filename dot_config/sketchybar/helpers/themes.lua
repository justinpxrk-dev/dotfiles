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

--- The active interface theme; refreshed from the system by `M.refresh()`.
--- @type ThemeMode
M.THEME = M.THEME_MODES.LIGHT

--- Refresh `M.THEME` from the macOS global `AppleInterfaceStyle` default, which
--- is absent in light mode and reads "Dark" in dark mode. If the command cannot
--- be run at all, `M.THEME` is left unchanged.
--- @return nil
function M.refresh()
	local f = io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")
	if f ~= nil then
		local is_dark_mode = (f:read("*a"):match("Dark") ~= nil)
		f:close()
		M.THEME = is_dark_mode and M.THEME_MODES.DARK or M.THEME_MODES.LIGHT
	end
end

--- Select between two values based on the active theme: returns `dark` in dark
--- mode and `light` otherwise. Both arguments are evaluated before the call, so
--- pass plain values rather than side-effecting expressions.
--- @generic T
--- @param dark T value to use when the theme is dark
--- @param light T value to use when the theme is light
--- @return T
function M.select(dark, light)
	if M.THEME == M.THEME_MODES.DARK then
		return dark
	end
	return light
end

--- Pack a "#RRGGBB" hex string into a sketchybar 0xAARRGGBB color integer.
--- @param hex string e.g. "#1e1e2e"
--- @param alpha integer? opacity byte 0x00-0xff (default 0xff, fully opaque)
--- @return integer color
function M.hex_to_color(hex, alpha)
	return ((alpha or 0xff) << 24) | tonumber(hex:sub(2), 16)
end

return M
