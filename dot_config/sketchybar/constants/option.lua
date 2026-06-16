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
--- @alias SpacesOption "APP_ICON" | "APP_TITLE" | "BRACKET" | "DIVIDER" | "GLYPH" | "NUM" | "SPACER"

--- @type Option
local M = {
	BAR = {
		-- External (LG) bottom bar: the floating, rounded style. `display` is a
		-- monitor index (sketchybar has no "secondary" selector) — 2 is the external
		-- here; flip to 1 if the bar lands on the built-in. Vanishes when undocked.
		BOTTOM = utils.merge(colorschemes.get_bar_color_options(), {
			corner_radius = 19,
			display = 2,
			font_smoothing = true,
			height = 38,
			margin = 14,
			padding_left = padding.BAR.PADDING_LEFT,
			padding_right = padding.BAR.PADDING_RIGHT,
			position = "bottom",
			shadow = true,
			y_offset = 7,
		}),
		-- Built-in top bar mirroring the macOS menu bar: flush to the top edge, full
		-- width, squared off, no float shadow. `main` is always the built-in panel.
		-- Pinned to pure opaque black rather than the themed background, so it stays
		-- black across light/dark (the top bar loads no theme handler to repaint it).
		-- `notch_width` reserves the camera-notch gap so the `position = "e"` space row
		-- (see `init/topbar.lua`) anchors just to the right of the notch. sketchybar
		-- derives the anchor from the live display center (≈ center + notch_width/2), so
		-- only the small notch-relative term is hardcoded — the dominant half-display
		-- offset is recomputed, surviving a resolution/scaling change far better than an
		-- absolute offset would. Tuned to 218 so the first box's left edge clears the
		-- physical notch (measured right edge ~1054pt on the ~1901pt-wide built-in, a
		-- ~206pt centered notch) by 10px. No effect on the external (notchless) bar.
		TOP = {
			color = 0xff000000,
			corner_radius = 0,
			display = "main",
			font_smoothing = true,
			height = 38,
			margin = 0,
			notch_width = 218,
			padding_left = padding.BAR.PADDING_LEFT,
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
	-- Static styling for the per-display space indicators. The handler layers the
	-- per-space colors (from `colorschemes.get_space_color_options`), `position`, and
	-- dynamic strings (number, app glyphs) on top of these at add/set time. Box layout,
	-- left to right: [number │ g1 g2 g3]. Each app glyph is its own item so the inter-icon
	-- gaps can be set with item-level padding; the handler sets every inter-element gap
	-- dynamically (see `glyph_options`). The frontmost-app name is NOT shown in the boxes —
	-- it lives in a separate active-app pill (`APP_ICON` + `APP_TITLE`, an Apple glyph and
	-- the front-app name) that the same handler maintains at the far edge of each bar.
	SPACES = {
		-- The box drawn behind a space's number/divider/glyph member items (and reused for
		-- the active-app pill): a dark surface fill inside a thin border. The handler layers
		-- the per-state fill + border color on top — mauve on the active space and the pill,
		-- a dim surface on inactive spaces (see `bracket_options`).
		BRACKET = {
			background = {
				border_width = 2,
				corner_radius = 8,
				drawing = true,
				height = 26,
			},
		},
		-- Number item (icon = the space index, for the `alt-<n>` hotkey). Icon padding is 0
		-- so the digit's slot is just the digit — the box's uniform 10px gaps come entirely
		-- from item-level padding, set by the handler (`num_options`): the left-border gap on
		-- the left, and on the right the inter-element gap to the divider (apps present) or the
		-- box edge gap (empty, keeping it symmetric). The font is also set by the handler (bold
		-- on the active space); it is left out here so the dynamic value isn't shadowed in the
		-- merge.
		NUM = {
			icon = {
				padding_left = 0,
				padding_right = 0,
			},
		},
		-- Divider between the number and the app glyphs: a real 2px-wide drawn line
		-- (a thin tall background), not a font character — sketchybar has no native
		-- separator item, so a hairline background is the idiomatic equivalent. The
		-- handler shows it only on spaces that have glyphs and colors it per state.
		-- Visibility is toggled via the item's own `drawing` flag (see `div_options`),
		-- NOT `background.drawing`, so the background line stays enabled here. Its side
		-- gaps come from the neighbours' padding (NUM right / g1 left).
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
		-- Glyph item: one MRU app's icon. The handler draws one per app with a window in
		-- the space — `g1`..`gN`, a variable count (no cap), named via `glyph_name`.
		-- Each glyph is its own item — rather than concatenating the ligatures into one
		-- label — so item-level padding can put a uniform gap *between* the icons (a single
		-- concatenated app-font string renders its glyphs flush against each other, which is
		-- the crowding this avoids). Both gaps are set dynamically per slot (`glyph_options`):
		-- the inter-element gap on the left, then either 0 (another element follows) or the
		-- edge gap (this glyph ends the box).
		-- Item-level paddings are intentionally omitted here: the handler always sets both,
		-- and a static value would shadow the dynamic one in the first-wins merge.
		GLYPH = {
			icon = { font = font.DEFAULT.APP_ICON },
			label = { drawing = false },
		},
		-- Active-app pill, Apple-logo half: an SF Symbol apple logo (U+1008FA) in SF Pro,
		-- drawn as the pill's leading icon (no label). `padding_left` is the pill's inner left margin
		-- (10px from the border); `padding_right` is the 10px gap to the title half. The
		-- handler (`app_icon_options`) layers on the foreground color. This pill is a
		-- standalone singleton at the bar's far edge — not one of the per-space boxes. Every
		-- gap is 10px, matching the space boxes.
		APP_ICON = {
			icon = {
				string = "\u{1008FA}",
				font = font.DEFAULT.APPLE,
			},
			label = { drawing = false },
			padding_left = 10,
			padding_right = 10,
		},
		-- Active-app pill, title half: the macOS frontmost app's name in bold SF Pro
		-- Display. `padding_left` is 0 (the Apple half owns the 10px inter-element gap);
		-- `padding_right` is the pill's inner right margin (10px to the border). The handler
		-- (`app_title_options`) layers on the name string and color.
		APP_TITLE = {
			icon = { drawing = false },
			label = { font = font.DEFAULT.APP_TITLE },
			padding_left = 0,
			padding_right = 10,
		},
		-- Transparent 5px gap placed on each side of every box (so adjacent boxes sit
		-- 10px apart). Adjacent brackets pack flush — bracket padding only grows
		-- interior width, never the gap — so the spacing must come from standalone
		-- non-member items.
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
