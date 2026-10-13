local sbar = require("sketchybar")

local event = require("constants.event")
local item = require("constants.item")
local option = require("constants.option")

local M = {}

--- Register the macOS light/dark notification as a sketchybar event, subscribe a
--- hidden listener that runs `on_change`, and trigger it once so colors initialize.
--- Each instance supplies a callback to refresh the palette and repaint its items.
--- @param on_change fun() invoked on every theme change and once at setup
--- @return nil
function M.setup(on_change)
	sbar.add("event", event.THEME.CHANGE, "AppleInterfaceThemeChangedNotification")
	sbar.add("item", item.THEME.EVENT_LISTENER, option.EVENT_LISTENER.OPTIONS):subscribe(event.THEME.CHANGE, on_change)
	sbar.trigger(event.THEME.CHANGE)
end

return M
