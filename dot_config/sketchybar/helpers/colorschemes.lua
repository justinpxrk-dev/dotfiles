local asset = require("constants.asset")
local themes = require("helpers.themes")

--- @class Colorschemes
--- @field COLORS ColorschemePalette
--- @field COLORSCHEMES table<ColorschemeOption, ColorschemePalette>
--- @alias ColorschemeOption "MACOS_TAHOE_DARK" | "MACOS_TAHOE_LIGHT"
--- @alias ColorschemePalette table<ColorschemePaletteOption, integer>
--- @alias ColorschemePaletteOption "ACTIVE_SPACE_ICON" | "BACKGROUND" | "BORDER" | "GRAPH" | "GRAPH_FILL" | "ICON" | "INACTIVE_LABEL" | "INACTIVE_SPACE_ICON" | "LABEL"
local M = {}

--- @type table<ColorschemeOption, ColorschemePalette>
local colorschemes = {
	MACOS_TAHOE_DARK = {
		ACTIVE_SPACE_ICON = 0xff729f5b,
		BACKGROUND = 0xf21e1e1e,
		BORDER = 0xf22c2c2c,
		GRAPH = 0xff729f5b,
		GRAPH_FILL = 0xf26d9a57,
		ICON = 0xff729f5b,
		INACTIVE_LABEL = 0xf26d9a57,
		INACTIVE_SPACE_ICON = 0xf2638f4d,
		LABEL = 0xff729f5b,
	},
	MACOS_TAHOE_LIGHT = {
		ACTIVE_SPACE_ICON = 0xff5e5e5e,
		BACKGROUND = 0xf2ebebeb,
		BORDER = 0xf2555555,
		GRAPH = 0xff5e5e5e,
		GRAPH_FILL = 0xf2595959,
		ICON = 0xff5e5e5e,
		INACTIVE_LABEL = 0xf2555555,
		INACTIVE_SPACE_ICON = 0xf2595959,
		LABEL = 0xff5e5e5e,
	},
}

--- @type ColorschemePalette
local colors = colorschemes.MACOS_TAHOE_LIGHT

function M.get_bar_color_options()
	return {
		border_color = colors.BORDER,
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
