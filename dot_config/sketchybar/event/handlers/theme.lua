local colorschemes = require("helpers.colorschemes")
local themes = require("helpers.themes")

local M = {}

--- Re-derive the active palette from the current system theme (Mocha in dark, Latte
--- in light) without repainting the bar. Both bars use this: their backgrounds are
--- static (transparent), but the chrome still needs the refreshed palette to recolor.
--- @return nil
function M.refresh_palette()
	themes.refresh()
	colorschemes.refresh()
end

return M
