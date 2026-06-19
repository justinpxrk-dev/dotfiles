local asset = require("constants.asset")
local catppuccin = require("catppuccin")
local themes = require("helpers.themes")

--- @class Colorschemes
--- @alias ColorschemePalette table<ColorschemePaletteOption, integer>
--- @alias ColorschemePaletteOption "ACTIVE_SPACE_BG" | "ACTIVE_SPACE_BORDER" | "ACTIVE_SPACE_FG" | "BACKGROUND" | "GRAPH" | "GRAPH_FILL" | "ICON" | "INACTIVE_LABEL" | "INACTIVE_SPACE_BG" | "INACTIVE_SPACE_BORDER" | "INACTIVE_SPACE_FG" | "LABEL"
local M = {}

--- Map a Catppuccin flavor palette (from the `catppuccin` LuaRocks module) to the
--- bar's semantic color roles. Translucent surfaces (background, graph fill,
--- inactive text/box) keep the 0xf2 alpha the bar used previously; foreground roles
--- are fully opaque. Palette colors are objects, so the hex is read via `.hex`.
---
--- The space-box roles drive the per-display space indicators: every box is a dim
--- translucent `surface0` fill. The visible (active) space has a `mauve` border and bright
--- `text` number/glyphs with its leading app glyph in `mauve`; inactive boxes have a dim
--- `surface1` border and a dimmer `overlay1` foreground. Every role tracks the live system
--- theme (Mocha in dark mode, Latte in light) — the palette is re-derived by `M.refresh`.
--- @param p table a Catppuccin flavor palette, e.g. `catppuccin.mocha()`
--- @return ColorschemePalette
local function roles(p)
	return {
		ACTIVE_SPACE_BG = themes.hex_to_color(p.surface0.hex, 0xf2),
		ACTIVE_SPACE_BORDER = themes.hex_to_color(p.mauve.hex),
		ACTIVE_SPACE_FG = themes.hex_to_color(p.text.hex),
		BACKGROUND = themes.hex_to_color(p.base.hex, 0xf2),
		GRAPH = themes.hex_to_color(p.text.hex),
		GRAPH_FILL = themes.hex_to_color(p.mantle.hex, 0xf2),
		ICON = themes.hex_to_color(p.text.hex),
		INACTIVE_LABEL = themes.hex_to_color(p.surface1.hex, 0xf2),
		INACTIVE_SPACE_BG = themes.hex_to_color(p.surface0.hex, 0xf2),
		INACTIVE_SPACE_BORDER = themes.hex_to_color(p.surface1.hex, 0xf2),
		INACTIVE_SPACE_FG = themes.hex_to_color(p.overlay1.hex),
		LABEL = themes.hex_to_color(p.text.hex),
	}
end

--- The active palette, re-derived from the system theme by `M.refresh()`.
--- @type ColorschemePalette
local colors = roles(catppuccin.latte())

--- The colour for the apple-badge / title-pill "knockout" glyphs and text: the bar's own
--- (themed) `BACKGROUND` role, so the glyph reads as a cutout of the bar within the mauve pill.
--- Tracks the live theme, so the knockout follows the bar's look in both light and dark.
--- @return integer ARGB colour
function M.get_bar_background()
	return colors.BACKGROUND
end

--- Default item color options shared by every item's icon and label.
--- @return table options sketchybar `icon` and `label` color overrides
function M.get_default_color_options()
	return {
		label = {
			color = colors.LABEL,
		},
		icon = {
			color = colors.ICON,
		},
	}
end

--- Now Playing artwork placeholder options. Picks the transparent logo image
--- matching the active theme, shown when no real track artwork is available.
--- @return table options sketchybar `background.image` override
function M.get_now_playing_artwork_logo_color_options()
	return {
		background = {
			image = {
				string = themes.select(
					asset.NOW_PLAYING.ARTWORK.DEFAULT_IMAGE_DARK_TRANSPARENT,
					asset.NOW_PLAYING.ARTWORK.DEFAULT_IMAGE_LIGHT_TRANSPARENT
				),
			},
		},
	}
end

--- Now Playing track label color options. Uses the active label color while a
--- track is playing and the dimmed inactive color when paused or stopped.
--- @param playing boolean whether a track is currently playing
--- @return table options sketchybar `label` color override
function M.get_now_playing_track_color_options(playing)
	return {
		label = {
			color = playing and colors.LABEL or colors.INACTIVE_LABEL,
		},
	}
end

--- Space-box color options for a single per-display space indicator. Returns the
--- bracket `background` (fill + border) and the member items' `icon`/`label` colors,
--- so the handler can paint the bracket and the number/glyph items in one shape. Every
--- role tracks the live theme (Mocha in dark, Latte in light), like the external bar. The
--- returned `dim` is the dimmer foreground (`overlay1`) for the active space's non-leading
--- app glyphs (the apps other than the focused one). Inactive spaces use a dim `surface1`
--- border (no mauve); the active space uses the bright `text` foreground and `mauve` border.
--- @param active boolean whether this is the display's visible (current) space
--- @return table options sketchybar `background`, `icon`, `label`, and `dim` color overrides
function M.get_space_color_options(active)
	local bg = active and colors.ACTIVE_SPACE_BG or colors.INACTIVE_SPACE_BG
	local border = active and colors.ACTIVE_SPACE_BORDER or colors.INACTIVE_SPACE_BORDER
	local fg = active and colors.ACTIVE_SPACE_FG or colors.INACTIVE_SPACE_FG
	return {
		background = {
			color = bg,
			border_color = border,
		},
		icon = {
			color = fg,
		},
		label = {
			color = fg,
		},
		dim = {
			color = colors.INACTIVE_SPACE_FG,
		},
	}
end

--- Resources CPU graph color options (line and fill).
--- @return table options sketchybar `graph` color overrides
function M.get_resources_graph_color_options()
	return {
		graph = {
			color = colors.GRAPH,
			fill_color = colors.GRAPH_FILL,
		},
	}
end

--- Re-derive the active palette from the current system theme: Catppuccin Mocha
--- in dark mode, Latte in light mode. Call after `themes.refresh()` so the new
--- theme is reflected before colors are read.
--- @return nil
function M.refresh()
	colors = roles(themes.select(catppuccin.mocha(), catppuccin.latte()))
end

return M
