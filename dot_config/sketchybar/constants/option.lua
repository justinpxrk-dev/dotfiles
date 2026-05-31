local font = require("constants.font")
local icon = require("constants.icon")
local padding = require("constants.padding")
local colorschemes = require("helpers.colorschemes")
local utils = require("helpers.utils")

--- @class Option
--- @field BAR table<BarOption, table<string, any>>
--- @field DEFAULT table<DefaultOption, table<string, any>>
--- @field EVENT_LISTENER table<EventListenerOption, table<string, any>>
--- @field NOW_PLAYING table<NowPlayingOption, table<string, any>>
--- @field RESOURCES table<ResourcesOption, table<string, any>>
--- @alias BarOption "OPTIONS"
--- @alias DefaultOption "OPTIONS"
--- @alias EventListenerOption "OPTIONS"
--- @alias NowPlayingOption "ARTWORK_OPTIONS" | "TRACK_OPTIONS"
--- @alias ResourcesOption "CPU" | "CPU_GRAPH"

--- @type Option
local M = {
	BAR = {
		OPTIONS = utils.merge(colorschemes.get_bar_color_options(), {
			border_width = 4,
			corner_radius = 19,
			display = "main",
			font_smoothing = true,
			height = 38,
			margin = 14,
			padding_left = padding.BAR.PADDING_LEFT,
			padding_right = padding.BAR.PADDING_RIGHT,
			position = "bottom",
			shadow = true,
			y_offset = 7,
		}),
	},
	DEFAULT = {
		OPTIONS = utils.merge(colorschemes.get_default_color_options(), {
			icon = {
				font = font.DEFAULT.ICON,
			},
			label = {
				font = font.DEFAULT.LABEL,
			},
			padding_left = padding.DEFAULT.PADDING_LEFT,
			padding_right = padding.DEFAULT.PADDING_RIGHT,
		}),
	},
	EVENT_LISTENER = {
		OPTIONS = {
			drawing = false,
		},
	},
	NOW_PLAYING = {
		ARTWORK_OPTIONS = utils.merge(colorschemes.get_now_playing_artwork_logo_color_options(), {
			background = {
				height = 24,
				image = {
					corner_radius = 6,
				},
				drawing = true,
			},
			padding_right = 0,
			position = "left",
		}),

		TRACK_OPTIONS = utils.merge(colorschemes.get_now_playing_track_color_options(false), {
			label = {
				max_chars = 40,
				string = "Not Playing",
			},
			position = "left",
			scroll_texts = true,
		}),
	},
	RESOURCES = {
		CPU = utils.merge(colorschemes.get_default_color_options(), {
			icon = {
				string = icon.RESOURCES.CPU,
			},
			padding_right = 0,
			position = "right",
		}),
		CPU_GRAPH = utils.merge(
			colorschemes.get_default_color_options(),
			colorschemes.get_resources_graph_color_options(),
			{
				background = {
					drawing = true,
					height = 24,
					y_offset = 3,
				},
				position = "right",
			}
		),
	},
}

return M
