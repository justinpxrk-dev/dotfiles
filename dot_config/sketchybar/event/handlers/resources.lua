local sbar = require("sketchybar")

local item = require("constants.item")
local colorschemes = require("helpers.colorschemes")
local utils = require("helpers.utils")

local M = {}

function M.theme_change_handler()
	local item_color_options = colorschemes.get_default_color_options()

	sbar.set(item.RESOURCES.CPU, item_color_options)
	sbar.set(
		item.RESOURCES.CPU_GRAPH,
		utils.merge(item_color_options, colorschemes.get_resources_graph_color_options())
	)
end

return M
