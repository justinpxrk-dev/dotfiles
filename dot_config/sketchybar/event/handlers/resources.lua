local sbar = require("sketchybar")

local colorschemes = require("helpers.colorschemes")
local item = require("constants.item")

local M = {}

--- Repaint the Stats widgets' leading SF Symbol icons from the live theme palette on a
--- light/dark switch. Stats colors the alias items themselves, so only our icons need it;
--- the top bar wires this into its theme `on_change`. Without it the icons keep their
--- startup color and would clash with the themed bar in the other mode.
--- @return nil
function M.theme_change_handler()
	local color_options = colorschemes.get_default_color_options()
	sbar.set(item.RESOURCES.CPU_ICON, color_options)
	sbar.set(item.RESOURCES.GPU_ICON, color_options)
	sbar.set(item.RESOURCES.RAM_ICON, color_options)
	sbar.set(item.RESOURCES.SENSORS_ICON, color_options)
end

return M
