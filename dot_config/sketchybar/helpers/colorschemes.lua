local asset = require("constants.asset")
local catppuccin = require("catppuccin")
local themes = require("helpers.themes")

--- @class Colorschemes
--- @alias ColorschemePalette table<ColorschemePaletteOption, integer>
--- @alias ColorschemePaletteOption "ACTIVE_SPACE_ICON" | "BACKGROUND" | "GRAPH" | "GRAPH_FILL" | "ICON" | "INACTIVE_LABEL" | "INACTIVE_SPACE_ICON" | "LABEL"
local M = {}

--- Map a Catppuccin flavor palette (from the `catppuccin` LuaRocks module) to the
--- bar's semantic color roles. Translucent surfaces (background, graph fill,
--- inactive text) keep the 0xf2 alpha the bar used previously; foreground roles
--- are fully opaque. Palette colors are objects, so the hex is read via `.hex`.
--- @param p table a Catppuccin flavor palette, e.g. `catppuccin.mocha()`
--- @return ColorschemePalette
local function roles(p)
	return {
		ACTIVE_SPACE_ICON = themes.hex_to_color(p.text.hex),
		BACKGROUND = themes.hex_to_color(p.base.hex, 0xf2),
		GRAPH = themes.hex_to_color(p.text.hex),
		GRAPH_FILL = themes.hex_to_color(p.mantle.hex, 0xf2),
		ICON = themes.hex_to_color(p.text.hex),
		INACTIVE_LABEL = themes.hex_to_color(p.surface1.hex, 0xf2),
		INACTIVE_SPACE_ICON = themes.hex_to_color(p.surface2.hex, 0xf2),
		LABEL = themes.hex_to_color(p.text.hex),
	}
end

--- The active palette, re-derived from the system theme by `M.refresh()`.
--- @type ColorschemePalette
local colors = roles(catppuccin.latte())

--- Bar background color options.
--- @return table options sketchybar bar `color` override
function M.get_bar_color_options()
	return {
		color = colors.BACKGROUND,
	}
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
