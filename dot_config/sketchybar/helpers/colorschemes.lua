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
		ACTIVE_SPACE_ICON = 0xffcdd6f4,
		BACKGROUND = 0xf21e1e2e,
		GRAPH = 0xffcdd6f4,
		GRAPH_FILL = 0xf2181825,
		ICON = 0xffcdd6f4,
		INACTIVE_LABEL = 0xf245475a,
		INACTIVE_SPACE_ICON = 0xf2585b70,
		LABEL = 0xffcdd6f4,
	},
	MACOS_TAHOE_LIGHT = {
		ACTIVE_SPACE_ICON = 0xff4c4f69,
		BACKGROUND = 0xf2eff1f5,
		GRAPH = 0xff4c4f69,
		GRAPH_FILL = 0xf2e6e9ef,
		ICON = 0xff4c4f69,
		INACTIVE_LABEL = 0xf2bcc0cc,
		INACTIVE_SPACE_ICON = 0xf2acb0be,
		LABEL = 0xff4c4f69,
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
