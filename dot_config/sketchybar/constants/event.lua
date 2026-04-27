--- @class Event
--- @field NOW_PLAYING table<NowPlayingEvent, string>
--- @field SPACES table<SpacesEvent, string>
--- @field THEME table<ThemeEvent, string>
--- @alias NowPlayingEvent "ARTWORK_CHANGE" | "PAUSE" | "STOP" | "TRACK_CHANGE" | "UNPAUSE"
--- @alias SpacesEvent "CHANGE"
--- @alias ThemeEvent "CHANGE"

--- @type Event
local M = {
	NOW_PLAYING = {
		ARTWORK_CHANGE = "now_playing_artwork_change",
		PAUSE = "now_playing_pause",
		STOP = "now_playing_stop",
		TRACK_CHANGE = "now_playing_track_change",
		UNPAUSE = "now_playing_unpause",
	},
	SPACES = {
		CHANGE = "spaces_change",
	},
	THEME = {
		CHANGE = "theme_change",
	},
}

return M
