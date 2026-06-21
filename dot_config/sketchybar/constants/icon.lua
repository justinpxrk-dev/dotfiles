--- @class Icon
--- @field RESOURCES table<ResourcesIcon, string>
--- @field SPACES table<SpacesIcon, string>
--- @field UPDATES table<UpdatesIcon, string>
--- @alias ResourcesIcon "CPU" | "GPU" | "RAM" | "SENSORS"
--- @alias SpacesIcon "DEFAULT"
--- @alias UpdatesIcon "BREW" | "MISE"

--- @type Icon
local M = {
	RESOURCES = {
		-- SF Symbols (rendered by SF Pro; see constants/font.lua). These are
		-- private-use-area glyphs, so they will most likely not be visible in the
		-- editor. One leads each resource widget, in front of its Stats alias
		-- (see plugins/resources.lua).
		CPU = "􀫥",
		GPU = "􀢹",
		RAM = "􀫦",
		SENSORS = "􂬮",
	},
	UPDATES = {
		-- Nerd Font glyphs (rendered by "Symbols Nerd Font"; see constants/font.lua), one leading
		-- each segment of the updates pill (see plugins/updates.lua). Written as `\u{...}` escapes,
		-- not literal glyphs: these are private-use-area codepoints that most editors (and this
		-- repo's tooling pipeline) will not render or even preserve on paste. Resolve a name to its
		-- codepoint against the installed font, e.g. by parsing its cmap/post tables.
		BREW = "\u{E7FD}", -- nf-dev-homebrew (the Homebrew logo)
		MISE = "\u{F0B7C}", -- nf-md-chef_hat (mise → "mise en place")
	},
	SPACES = {
		DEFAULT = "󰣆",
	},
}

return M
