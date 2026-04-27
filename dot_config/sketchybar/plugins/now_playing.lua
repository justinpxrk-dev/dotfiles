local sbar = require("sketchybar")

local event = require("constants.event")
local item = require("constants.item")
local option = require("constants.option")
local now_playing = require("event.handlers.now_playing")

sbar.add("event", event.NOW_PLAYING.ARTWORK_CHANGE)
sbar.add("event", event.NOW_PLAYING.PAUSE)
sbar.add("event", event.NOW_PLAYING.STOP)
sbar.add("event", event.NOW_PLAYING.TRACK_CHANGE)
sbar.add("event", event.NOW_PLAYING.UNPAUSE)

sbar.add("item", item.NOW_PLAYING.ARTWORK, option.NOW_PLAYING.ARTWORK_OPTIONS)
sbar.add("item", item.NOW_PLAYING.TRACK, option.NOW_PLAYING.TRACK_OPTIONS)

local event_listener = sbar.add("item", item.NOW_PLAYING.EVENT_LISTENER, option.EVENT_LISTENER.OPTIONS)
event_listener:subscribe(event.NOW_PLAYING.ARTWORK_CHANGE, function(env)
	now_playing.artwork_change_handler(env)
end)
event_listener:subscribe(event.NOW_PLAYING.TRACK_CHANGE, function(env)
	now_playing.track_change_handler(env)
end)
event_listener:subscribe(event.NOW_PLAYING.PAUSE, now_playing.pause_handler)
event_listener:subscribe(event.NOW_PLAYING.UNPAUSE, now_playing.unpause_handler)
event_listener:subscribe(event.NOW_PLAYING.STOP, now_playing.stop_handler)

sbar.exec(os.getenv("HOME") .. "/.config/sketchybar/event/dispatchers/now_playing.sh &")
