local sbar = require("sketchybar")

local option = require("constants.option")
local now_playing = require("event.handlers.now_playing")
local resources = require("event.handlers.resources")
local spaces = require("event.handlers.spaces")
local theme = require("event.handlers.theme")

-- Initialize bar and default options
sbar.default(option.DEFAULT.OPTIONS)
sbar.bar(option.BAR.BOTTOM)

theme.refresh_palette()
spaces.setup({
	display_uuid = "8504812E-7847-4FC1-8787-047CEB3BF80A",
	position = "center",
	app_position = "center",
})

-- Add left bar plugins
require("plugins.now_playing")
-- Add center bar plugins
require("plugins.spaces")
-- Add right bar plugins
require("plugins.resources")

-- Recolor every item on light/dark switch (and once at startup); the transparent bar
-- background is static and never repainted. Loaded last so all items exist before the
-- initial trigger fires.
require("plugins.theme").setup(function()
	theme.refresh_palette()
	now_playing.theme_change_handler()
	resources.theme_change_handler()
	spaces.theme_change_handler()
end)
