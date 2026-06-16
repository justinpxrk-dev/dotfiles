--- @class Item
--- @field NOW_PLAYING table<NowPlayingItem, string>
--- @field RESOURCES table<ResourcesItem, string>
--- @field SPACES table<SpacesItem, string>
--- @field THEME table<ThemeItem, string>
--- @alias NowPlayingItem "ARTWORK" | "EVENT_LISTENER" | "TRACK"
--- @alias ResourcesItem "CPU_ALIAS" | "CPU_ICON" | "GPU_ALIAS" | "GPU_ICON" | "RAM_CHART_ALIAS" | "RAM_ICON" | "RAM_STATE_ALIAS" | "SENSORS_ALIAS" | "SENSORS_ICON"
--- @alias SpacesItem "APPLE" | "APPLE_BRACKET" | "APPLE_SPACER" | "APP_BRACKET" | "APP_ICON" | "APP_SPACER" | "APP_SPACER_L" | "APP_TITLE" | "EVENT_LISTENER" | "PREFIX"
--- @alias ThemeItem "EVENT_LISTENER"

--- @type Item
local M = {
	NOW_PLAYING = {
		ARTWORK = "now_playing_artwork",
		TRACK = "now_playing_track",
		EVENT_LISTENER = "now_playing_event_listener",
	},
	RESOURCES = {
		-- Internal sketchybar item names for the SF Symbol icon that leads each
		-- resource widget.
		CPU_ICON = "resources_cpu_icon",
		GPU_ICON = "resources_gpu_icon",
		RAM_ICON = "resources_ram_icon",
		SENSORS_ICON = "resources_sensors_icon",

		-- macOS menu-bar identifiers for the Stats widgets mirrored as `alias`
		-- items. An alias item's name MUST equal its source's "<owner>,<name>";
		-- discover live values with `sketchybar --query default_menu_items`. On
		-- macOS 26 third-party items are owned by "Control Center" (not "Stats"),
		-- so this map is OS-version- and Stats-config-specific — see
		-- docs/ops/upgrade-hazards.md. RAM is split into a separate `_state` status
		-- icon + chart because its Stats `oneView` is off.
		CPU_ALIAS = "Control Center,CPU",
		GPU_ALIAS = "Control Center,GPU",
		RAM_STATE_ALIAS = "Control Center,RAM_state",
		RAM_CHART_ALIAS = "Control Center,RAM_bar_chart",
		SENSORS_ALIAS = "Control Center,Sensors",
	},
	-- Space indicators are dynamic (one set of items per live space), so their names
	-- are built at runtime from PREFIX, e.g. `spaces.3.num` / `.div` / `.bracket`. The
	-- `APP_*` names are singletons (one active-app pill per bar), kept under the same
	-- namespace but with a non-numeric segment so they never collide with a space index.
	SPACES = {
		EVENT_LISTENER = "spaces_event_listener",
		PREFIX = "spaces.",
		-- Apple-logo badge pill (mauve box, surface-colored Apple glyph), left of the title pill.
		APPLE = "spaces.app_title.apple",
		APPLE_SPACER = "spaces.app_title.apple_spacer",
		APPLE_BRACKET = "spaces.app_title.apple_bracket",
		-- Title pill: the active app's icon glyph + name.
		APP_ICON = "spaces.app_title.icon",
		APP_TITLE = "spaces.app_title.label",
		APP_SPACER_L = "spaces.app_title.spacer_l",
		APP_SPACER = "spaces.app_title.spacer",
		APP_BRACKET = "spaces.app_title.bracket",
	},
	THEME = { EVENT_LISTENER = "theme_event_listener" },
}

return M
