--- @class Item
--- @field NOW_PLAYING table<NowPlayingItem, string>
--- @field RESOURCES table<ResourcesItem, string>
--- @field SPACES table<SpacesItem, string>
--- @field THEME table<ThemeItem, string>
--- @alias NowPlayingItem "ARTWORK" | "EVENT_LISTENER" | "TRACK"
--- @alias ResourcesItem "CPU" | "CPU_GRAPH" | "EVENT_LISTENER"
--- @alias SpacesItem "EVENT_LISTENER"
--- @alias ThemeItem "EVENT_LISTENER"

--- @type Item
local M = {
	NOW_PLAYING = {
		ARTWORK = "now_playing_artwork",
		TRACK = "now_playing_track",
		EVENT_LISTENER = "now_playing_event_listener",
	},
	RESOURCES = {
		CPU = "resources_cpu",
		CPU_GRAPH = "resource_cpu_graph",
		EVENT_LISTENER = "resources_event_listener",
	},
	SPACES = { EVENT_LISTENER = "spaces_event_listener" },
	THEME = { EVENT_LISTENER = "theme_event_listener" },
}

return M
