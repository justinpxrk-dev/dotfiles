local sbar = require("sketchybar")

local option = require("constants.option")
local spaces = require("event.handlers.spaces")
local theme = require("event.handlers.theme")

-- Built-in top bar (default instance), mirroring the macOS menu bar.
sbar.default(option.DEFAULT.OPTIONS)
sbar.bar(option.BAR.TOP)

theme.refresh_palette()
spaces.setup({
	display_uuid = "37D8832A-2D66-02CA-B9F7-8F30A301B230",
	position = "e",
	left_position = "q",
	app_position = "q",
	apple_position = "left",
})

-- Add space indicators
require("plugins.spaces")

-- Recolor the space boxes and app pill on light/dark switch (and once at startup). The bar
-- background is transparent, so only the items need recolouring.
require("plugins.theme").setup(function()
	theme.refresh_palette()
	spaces.theme_change_handler()
end)
