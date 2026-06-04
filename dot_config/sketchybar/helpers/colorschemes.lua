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

--- @type ColorschemePalette
local colors = roles(catppuccin.latte())

function M.get_bar_color_options()
	return {
		color = colors.BACKGROUND,
	}
end

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

function M.get_now_playing_artwork_logo_color_options()
	if themes.THEME == themes.THEME_MODES.DARK then
		return {
			background = {
				image = {
					string = asset.NOW_PLAYING.ARTWORK.DEFAULT_IMAGE_DARK_TRANSPARENT,
				},
			},
		}
	else
		return {
			background = {
				image = {
					string = asset.NOW_PLAYING.ARTWORK.DEFAULT_IMAGE_LIGHT_TRANSPARENT,
				},
			},
		}
	end
end

function M.get_now_playing_track_color_options(playing)
	if playing then
		return {
			label = {
				color = colors.LABEL,
			},
		}
	else
		return {
			label = {
				color = colors.INACTIVE_LABEL,
			},
		}
	end
end

function M.get_resources_graph_color_options()
	return {
		graph = {
			color = colors.GRAPH,
			fill_color = colors.GRAPH_FILL,
		},
	}
end

function M.refresh()
	if themes.THEME == themes.THEME_MODES.DARK then
		colors = roles(catppuccin.mocha())
	else
		colors = roles(catppuccin.latte())
	end
end

return M
