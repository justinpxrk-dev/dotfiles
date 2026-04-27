local sbar = require("sketchybar")

local event = require("constants.event")
local item = require("constants.item")
local option = require("constants.option")
local spaces = require("event.handlers.spaces")

sbar.add("event", event.SPACES.CHANGE)

local event_listener = sbar.add("item", item.SPACES.EVENT_LISTENER, option.EVENT_LISTENER.OPTIONS)
event_listener:subscribe(event.SPACES.CHANGE, spaces.spaces_change_handler)

sbar.trigger(event.SPACES.CHANGE)
