--- @class Item
--- @field NOW_PLAYING table<NowPlayingItem, string>
--- @field RESOURCES table<ResourcesItem, string>
--- @field SPACES table<SpacesItem, string>
--- @field THEME table<ThemeItem, string>
--- @alias NowPlayingItem "ARTWORK" | "EVENT_LISTENER" | "TRACK"
--- @alias ResourcesItem "CPU" | "CPU_GRAPH" | "EVENT_LISTENER"
--- @alias SpacesItem "APPLE" | "APPLE_BRACKET" | "APPLE_SPACER" | "APP_BRACKET" | "APP_ICON" | "APP_SPACER" | "APP_TITLE" | "EVENT_LISTENER" | "PREFIX"
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
		CPU_GRAPH = "resources_cpu_graph",
		EVENT_LISTENER = "resources_event_listener",
	},
	-- Space indicators are dynamic (one set of items per live space), so their names
	-- are built at runtime from PREFIX, e.g. `spaces.3.num` / `.div` / `.bracket`. The
	-- `APP_*` names are singletons (one active-app pill per bar), kept under the same
	-- namespace but with a non-numeric segment so they never collide with a space index.
	SPACES = {
		EVENT_LISTENER = "spaces_event_listener",
		PREFIX = "spaces.",
		-- Apple-logo badge pill (mauve box, surface-colored Apple glyph): a standalone singleton at
		-- the top bar's far-left edge, omitted on the external bar. APPLE_SPACER is its trailing gap
		-- to the next pill that shares the `"left"` region.
		APPLE = "spaces.app_title.apple",
		APPLE_SPACER = "spaces.app_title.apple_spacer",
		APPLE_BRACKET = "spaces.app_title.apple_bracket",
		-- Title pill: the active app's icon glyph + name. APP_SPACER is its trailing gap to the
		-- first space box.
		APP_ICON = "spaces.app_title.icon",
		APP_TITLE = "spaces.app_title.label",
		APP_SPACER = "spaces.app_title.spacer",
		APP_BRACKET = "spaces.app_title.bracket",
	},
	THEME = { EVENT_LISTENER = "theme_event_listener" },
}

return M
