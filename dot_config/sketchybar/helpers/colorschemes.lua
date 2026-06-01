local asset = require("constants.asset")
local themes = require("helpers.themes")

--- @class Colorschemes
--- @field COLORS ColorschemePalette
--- @field COLORSCHEMES table<ColorschemeOption, ColorschemePalette>
--- @alias ColorschemeOption "MACOS_TAHOE_DARK" | "MACOS_TAHOE_LIGHT"
--- @alias ColorschemePalette table<ColorschemePaletteOption, integer>
--- @alias ColorschemePaletteOption "ACTIVE_SPACE_ICON" | "BACKGROUND" | "GRAPH" | "GRAPH_FILL" | "ICON" | "INACTIVE_LABEL" | "INACTIVE_SPACE_ICON" | "LABEL"
local M = {}

--- @type table<ColorschemeOption, ColorschemePalette>
local colorschemes = {
	MACOS_TAHOE_DARK = {
		ACTIVE_SPACE_ICON = 0xffa9b1d6,
		BACKGROUND = 0xf21a1b26,
		GRAPH = 0xffa9b1d6,
		GRAPH_FILL = 0xf2444b6a,
		ICON = 0xffa9b1d6,
		INACTIVE_LABEL = 0xf2444b6a,
		INACTIVE_SPACE_ICON = 0xf2787c99,
		LABEL = 0xffa9b1d6,
	},
	MACOS_TAHOE_LIGHT = {
		ACTIVE_SPACE_ICON = 0xff343b59,
		BACKGROUND = 0xf2d5d6db,
		GRAPH = 0xff343b59,
		GRAPH_FILL = 0xf29699a3,
		ICON = 0xff343b59,
		INACTIVE_LABEL = 0xf29699a3,
		INACTIVE_SPACE_ICON = 0xf24c505e,
		LABEL = 0xff343b59,
	},
}

--- @type ColorschemePalette
local colors = colorschemes.MACOS_TAHOE_LIGHT

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
		colors = colorschemes.MACOS_TAHOE_DARK
	else
		colors = colorschemes.MACOS_TAHOE_LIGHT
	end
end

return M
