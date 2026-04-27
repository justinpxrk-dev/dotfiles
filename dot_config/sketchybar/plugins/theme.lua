local sbar = require("sketchybar")

local event = require("constants.event")
local item = require("constants.item")
local option = require("constants.option")
local now_playing = require("event.handlers.now_playing")
local resources = require("event.handlers.resources")
local spaces = require("event.handlers.spaces")
local theme = require("event.handlers.theme")

sbar.add("event", event.THEME.CHANGE, "AppleInterfaceThemeChangedNotification")

sbar.add("item", item.THEME.EVENT_LISTENER, option.EVENT_LISTENER.OPTIONS):subscribe(event.THEME.CHANGE, function()
	theme.theme_change_handler()
	now_playing.theme_change_handler()
	resources.theme_change_handler()
	spaces.theme_change_handler()
end)

sbar.trigger(event.THEME.CHANGE)
