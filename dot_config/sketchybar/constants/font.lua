--- @class Font
--- @field DEFAULT table<DefaultFontOption, FontSettings>
--- @alias DefaultFontOption "BOLD_LABEL" | "ICON" | "LABEL" | "APP_ICON" | "APP_TITLE" | "APPLE" | "NERD_FONT"
--- @alias FontSettings table<FontSetting, string | number>
--- @alias FontSetting "family" | "style" | "size"

--- @type Font
local M = {
	DEFAULT = {
		BOLD_LABEL = {
			family = "SF Pro",
			style = "Bold",
			size = 13.0,
		},
		ICON = {
			family = "SF Pro",
			style = "Regular",
			size = 13.0,
		},
		LABEL = {
			family = "SF Pro",
			style = "Regular",
			size = 13.0,
		},
		APP_ICON = {
			family = "sketchybar-app-font",
			style = "Regular",
			size = 14.0,
		},
		-- Active-app pill's title: bold SF Pro Display at the same 13pt as the Now
		-- Playing track label, so the front-app name stands out next to the Apple glyph
		-- while matching the bar's text size.
		APP_TITLE = {
			family = "SF Pro Display",
			style = "Bold",
			size = 13.0,
		},
		-- Apple-logo SF Symbol (U+1008FA) for the active-app pill, rendered by SF Pro; the
		-- sketchybar-app-font has no standalone Apple logo. Sized at 14pt to match the app
		-- glyphs in the space boxes, so it reads as a peer of the bold title.
		APPLE = {
			family = "SF Pro",
			style = "Bold",
			size = 14.0,
		},
		-- Nerd Font symbol family for the updates pill's per-segment glyphs (see constants/icon.lua
		-- and plugins/updates.lua). The proportional "Symbols Nerd Font" (NOT "…Mono"): Mono force-
		-- fits every glyph into one fixed cell, which only matters in a terminal grid and shrinks the
		-- wider icons — a bar renders each glyph at its natural width. Sized 14pt to match the app
		-- glyphs / Apple badge. Requires the font installed (it ships separately from the MonoLisa
		-- Nerd Font patch) — see docs/ops/upgrade-hazards.md.
		NERD_FONT = {
			family = "Symbols Nerd Font",
			style = "Regular",
			size = 14.0,
		},
	},
}

return M
