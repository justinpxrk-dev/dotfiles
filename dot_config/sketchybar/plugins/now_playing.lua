local sbar = require("sketchybar")

local colorschemes = require("helpers.colorschemes")
local event = require("constants.event")
local item = require("constants.item")
local option = require("constants.option")
local utils = require("helpers.utils")
local now_playing = require("event.handlers.now_playing")

sbar.add("event", event.NOW_PLAYING.ARTWORK_CHANGE)
sbar.add("event", event.NOW_PLAYING.PAUSE)
sbar.add("event", event.NOW_PLAYING.STOP)
sbar.add("event", event.NOW_PLAYING.TRACK_CHANGE)
sbar.add("event", event.NOW_PLAYING.UNPAUSE)

sbar.add("item", item.NOW_PLAYING.ARTWORK, option.NOW_PLAYING.ARTWORK_OPTIONS)
sbar.add("item", item.NOW_PLAYING.TRACK, option.NOW_PLAYING.TRACK_OPTIONS)

-- Frame the artwork + track as one surface pill: the dim inactive-space fill + border, reusing the
-- space box's surface styling and the Stats/clock pills' construction, so it reads as a sibling of
-- them. The pill carries no mauve accent, but its surface still tracks the live theme — the
-- now-playing theme handler repaints this bracket on a light/dark switch (see
-- event/handlers/now_playing.lua:theme_change_handler). The artwork/track `padding_*` set its inner
-- margins; added after its members so they already exist. Only the top bar carries now-playing (the
-- external bar omits it).
local pill_colors = colorschemes.get_space_color_options(false)
sbar.add(
	"bracket",
	item.NOW_PLAYING.PILL,
	{ item.NOW_PLAYING.ARTWORK, item.NOW_PLAYING.TRACK },
	utils.merge(option.SPACES.BRACKET, { background = pill_colors.background })
)

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
