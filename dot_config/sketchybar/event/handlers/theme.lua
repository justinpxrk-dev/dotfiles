local sbar = require("sketchybar")

local colorschemes = require("helpers.colorschemes")
local themes = require("helpers.themes")

local M = {}

function M.theme_change_handler()
	themes.refresh()
	colorschemes.refresh()
	sbar.bar(colorschemes.get_bar_color_options())
end

return M
