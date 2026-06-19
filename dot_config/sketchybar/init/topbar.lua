local sbar = require("sketchybar")

local option = require("constants.option")
local resources = require("event.handlers.resources")
local spaces = require("event.handlers.spaces")
local theme = require("event.handlers.theme")

-- Built-in top bar (default instance), mirroring the macOS menu bar.
sbar.default(option.DEFAULT.OPTIONS)
sbar.bar(option.BAR.TOP)

-- This instance renders the built-in display's (yabai display 1) spaces, split across the
-- camera notch and balanced including the active-app pill: the pill plus the first floor(n/2)
-- spaces (by sorted index) flank its left via the notch-aware `"q"` region, the rest its right
-- via `"e"`. sketchybar computes each anchor from the live display
-- center and the bar's `notch_width` (set on `option.BAR.TOP`), so the row stays notch-aligned
-- without a hand-measured offset and survives a resolution/scaling change. (`position =
-- "center"` lands dead-center behind the notch — center items "make no sense on notched
-- screens" per the docs — so it is not an option here.) Refresh the palette up front so the
-- first space paint is already themed; the bar background is static (never repainted here).
spaces.DISPLAY = 1
spaces.POSITION = "e"
spaces.POSITION_LEFT = "q"
-- The title pill (active app's icon + name) shares the left-of-notch `"q"` region, leading the
-- left-side spaces. The standalone Apple badge sits apart in the far-left `"left"` region
-- (mirroring the macOS Apple menu's top-left corner).
spaces.APP_POSITION = "q"
spaces.APPLE_POSITION = "left"
theme.refresh_palette()
-- Create the active-app pill items (the far-left Apple badge + the left-of-notch title pill)
-- before the space boxes are rendered.
spaces.setup_app_pill()

-- Add space indicators
require("plugins.spaces")

-- Mirror Stats resource widgets (CPU/GPU/RAM/Sensors/battery) plus the macOS clock into the right
-- region: Stats-colored aliases plus sketchybar-colored SF Symbol icons and pill/divider chrome,
-- with the clock as its own pill at the right end. The icons and chrome track the live theme, so
-- the `on_change` below repaints them (resources.theme_change_handler).
require("plugins.resources")

-- Repaint every themed item on a light/dark switch (and once at startup): the space boxes + app
-- pill, the Stats pill/icons/dividers. The bar background is transparent, so only the items need
-- recolouring.
require("plugins.theme").setup(function()
	theme.refresh_palette()
	spaces.theme_change_handler()
	resources.theme_change_handler()
end)
