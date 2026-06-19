local sbar = require("sketchybar")

local option = require("constants.option")
local spaces = require("event.handlers.spaces")
local theme = require("event.handlers.theme")

-- Built-in top bar (default instance), mirroring the macOS menu bar.
sbar.default(option.DEFAULT.OPTIONS)
sbar.bar(option.BAR.TOP)

-- This instance renders the built-in display's (yabai display 1) spaces, anchored to
-- the right of the camera notch via the notch-aware `"e"` position region. sketchybar
-- computes that anchor from the live display center and the bar's `notch_width` (set on
-- `option.BAR.TOP`), so the row stays notch-aligned without a hand-measured offset and
-- survives a resolution/scaling change. (`position = "center"` lands dead-center behind
-- the notch — center items "make no sense on notched screens" per the docs — so it is
-- not an option here.) Refresh the palette up front so the first space paint is already
-- themed; the on_change below repaints the themed bar background, like the external bar.
spaces.DISPLAY = 1
spaces.POSITION = "e"
-- The active-app pill mirrors the space row across the notch: `"q"` (left of notch).
spaces.APP_POSITION = "q"
theme.refresh_palette()
-- Create the active-app pill (left of notch) before the space boxes are rendered.
spaces.setup_app_pill()

-- Add space indicators
require("plugins.spaces")

-- Repaint the themed bar background and the space boxes on light/dark switch (and once at
-- startup), like the external bar.
require("plugins.theme").setup(function()
	theme.theme_change_handler()
	spaces.theme_change_handler()
end)
