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
--- @field SPACES table<SpacesOption, table<string, any>>
--- @alias BarOption "TOP" | "BOTTOM"
--- @alias DefaultOption "OPTIONS"
--- @alias EventListenerOption "OPTIONS"
--- @alias NowPlayingOption "ARTWORK_OPTIONS" | "TRACK_OPTIONS"
--- @alias ResourcesOption "CPU" | "CPU_GRAPH"
--- @alias SpacesOption "APPLE" | "APPLE_SPACER" | "APP_ICON" | "APP_TITLE" | "BRACKET" | "DIVIDER" | "GLYPH" | "NUM" | "SPACER"

--- @type Option
local M = {
	BAR = {
		-- Display targeting is resolved by UUID before the first visible render.
		BOTTOM = {
			color = 0x00000000,
			corner_radius = 0,
			hidden = true,
			font_smoothing = true,
			height = 38,
			margin = 0,
			padding_left = padding.BAR.PADDING_LEFT,
			padding_right = padding.BAR.PADDING_RIGHT,
			position = "bottom",
			shadow = false,
			y_offset = 0,
		},
		TOP = {
			color = 0x00000000,
			corner_radius = 0,
			hidden = true,
			font_smoothing = true,
			height = 42,
			margin = 0,
			-- Tuned in points for this panel; see the notch notes in upgrade-hazards.md.
			notch_width = 244,
			padding_left = 10,
			padding_right = padding.BAR.PADDING_RIGHT,
			position = "top",
			shadow = false,
			y_offset = 0,
		},
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
	-- Geometry only: views/spaces.lua supplies content, colors, and region order.
	SPACES = {
		BRACKET = {
			background = {
				border_width = 2,
				corner_radius = 8,
				drawing = true,
				height = 28,
			},
		},
		NUM = {
			label = { drawing = false },
			icon = {
				padding_left = 0,
				padding_right = 0,
			},
		},
		DIVIDER = {
			background = {
				corner_radius = 0,
				drawing = true,
				height = 14,
			},
			icon = { drawing = false },
			label = { drawing = false },
			padding_left = 0,
			padding_right = 0,
			width = 2,
		},
		GLYPH = {
			icon = { font = font.DEFAULT.APP_ICON },
			label = { drawing = false },
		},
		APPLE = {
			icon = {
				string = "\u{1008FA}",
				font = font.DEFAULT.APPLE,
			},
			label = { drawing = false },
			padding_left = 10,
			padding_right = 10,
		},
		APPLE_SPACER = {
			drawing = true,
			icon = { drawing = false },
			label = { drawing = false },
			padding_left = 0,
			padding_right = 0,
			width = 10,
		},
		APP_ICON = {
			icon = {
				font = font.DEFAULT.APP_ICON,
			},
			label = { drawing = false },
			padding_left = 10,
			padding_right = 5,
		},
		APP_TITLE = {
			icon = { drawing = false },
			label = { font = font.DEFAULT.APP_TITLE },
			padding_left = 0,
			padding_right = 10,
		},
		-- A 5px spacer on each box edge leaves 10px between neighboring boxes.
		SPACER = {
			drawing = true,
			icon = { drawing = false },
			label = { drawing = false },
			padding_left = 0,
			padding_right = 0,
			width = 5,
		},
	},
}

return M
