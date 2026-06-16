local sbar = require("sketchybar")

local option = require("constants.option")
local now_playing = require("event.handlers.now_playing")
local spaces = require("event.handlers.spaces")
local theme = require("event.handlers.theme")

-- Initialize bar and default options
sbar.default(option.DEFAULT.OPTIONS)
sbar.bar(option.BAR.BOTTOM)

-- This instance renders the external display's (yabai display 2) spaces, centered. The
-- active-app pill shares that centered region and is created first, so it is the left-most
-- pill in the cluster. Refresh the palette up front so the first space paint is themed.
spaces.DISPLAY = 2
spaces.POSITION = "center"
spaces.APP_POSITION = "center"
theme.refresh_palette()
-- Create the active-app pill before the space boxes so it leads the centered cluster.
spaces.setup_app_pill()

-- Add left bar plugins
require("plugins.now_playing")
-- Add center bar plugins
require("plugins.spaces")

-- Repaint the themed bar and every item on light/dark switch (and once at startup).
-- Loaded last so all items exist before the initial trigger fires.
require("plugins.theme").setup(function()
	theme.theme_change_handler()
	now_playing.theme_change_handler()
	spaces.theme_change_handler()
end)
