local sbar = require("sketchybar")

local colorschemes = require("helpers.colorschemes")
local themes = require("helpers.themes")

local M = {}

--- Re-derive the active palette from the current system theme (Mocha in dark, Latte
--- in light) without repainting the bar. The top bar uses this: it keeps its fixed
--- black background but still needs the refreshed palette to recolor its space boxes.
--- @return nil
function M.refresh_palette()
	themes.refresh()
	colorschemes.refresh()
end

--- Refresh the palette and repaint the themed bar background. The external bar uses
--- this so its background tracks light/dark.
--- @return nil
function M.theme_change_handler()
	M.refresh_palette()
	sbar.bar(colorschemes.get_bar_color_options())
end

return M
