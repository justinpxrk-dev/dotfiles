local font = require("constants.font")
local icon = require("constants.icon")
local padding = require("constants.padding")
local colorschemes = require("helpers.colorschemes")
local utils = require("helpers.utils")

-- Shared options for every resource widget: the right region with no padding, so the
-- icons, graphs, and status icons butt together — adjust `padding_left`/`padding_right`
-- here to space them. `alias.update_freq` is the Stats re-capture cadence in seconds
-- (Stats updates ~1s; 2s keeps capture cost low — tune to taste).
local resource_opts = {
	position = "right",
	padding_left = 0,
	padding_right = 0,
}
local alias_opts = utils.merge(resource_opts, { alias = { update_freq = 2 } })

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
--- @alias ResourcesOption "ALIAS" | "CPU_ICON" | "GPU_ICON" | "RAM_ICON" | "SENSORS_ICON"
--- @alias SpacesOption "APPLE" | "APPLE_SPACER" | "APP_ICON" | "APP_TITLE" | "BRACKET" | "DIVIDER" | "GLYPH" | "NUM" | "SPACER"

--- @type Option
local M = {
	BAR = {
		-- External (LG) bottom bar: flush to the bottom edge, squared off, fully transparent so
		-- its items float over the desktop. `display` is a monitor index (sketchybar has no
		-- "secondary" selector) — 2 is the external here; flip to 1 if the bar lands on the
		-- built-in. Vanishes when undocked.
		BOTTOM = {
			color = 0x00000000,
			corner_radius = 0,
			display = 2,
			font_smoothing = true,
			height = 38,
			margin = 0,
			padding_left = padding.BAR.PADDING_LEFT,
			padding_right = padding.BAR.PADDING_RIGHT,
			position = "bottom",
			shadow = false,
			y_offset = 0,
		},
		-- Built-in top bar mirroring the macOS menu bar: flush to the top edge, full
		-- width, squared off, no float shadow. `main` is always the built-in panel.
		-- Background is fully transparent (`0x00000000`), so its items float over the
		-- desktop; the bar colour itself needs no repaint, but its items track light/dark
		-- (see init/topbar.lua's theme `on_change`).
		-- `notch_width` reserves the camera-notch gap so the `position = "e"` space row
		-- (see `init/topbar.lua`) anchors just to the right of the notch. sketchybar
		-- derives the anchor from the live display center (≈ center + notch_width/2), so
		-- only the small notch-relative term is hardcoded — the dominant half-display
		-- offset is recomputed, surviving a resolution/scaling change far better than an
		-- absolute offset would. Tuned to 244 so the first box's left edge clears the
		-- physical notch (measured right edge ~1197pt on the 2160pt-wide built-in, a
		-- ~234pt centered notch) by 10px. No effect on the external (notchless) bar.
		TOP = {
			color = 0x00000000,
			corner_radius = 0,
			display = "main",
			font_smoothing = true,
			height = 42,
			margin = 0,
			notch_width = 244,
			-- 10px (not the shared 15px) so the far-left Apple badge — the left-most item on this
			-- flush-to-edge bar (margin 0) — sits 10px from the screen's left edge; the now-playing
			-- pill that follows it in the `"left"` region shifts with it, keeping their 10px gap.
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
		-- Album-art thumbnail, the now-playing pill's left half: a 20px rounded image — the real
		-- artwork (pre-sized to 20x20 by the dispatcher) or the Apple Music placeholder logo. Sized
		-- 1:1 to `background.height`, since sketchybar draws the image at the background height with
		-- no scale factor; the dispatcher's resize, this height, and the placeholder PNGs must all
		-- agree (see event/dispatchers/now_playing.sh and assets/apple-music). `padding_left` is the
		-- pill's inner-left margin (to the bracket border); `padding_right` the gap to the track label.
		-- `false`: the bar starts in the "Not Playing" state, so the placeholder uses the dim
		-- (inactive) tint. The theme handler re-sets it from the live theme once a state is known;
		-- this only sets the initial colour.
		ARTWORK_OPTIONS = utils.merge(colorschemes.get_now_playing_artwork_logo_color_options(false), {
			background = {
				height = 20,
				image = {
					corner_radius = 6,
				},
				drawing = true,
			},
			padding_left = 10,
			padding_right = 5,
			position = "left",
		}),

		-- Scrolling track label, the pill's right half. `padding_left` is 0 (the artwork owns the gap
		-- between them); `padding_right` is the pill's inner-right margin to the bracket border.
		TRACK_OPTIONS = utils.merge(colorschemes.get_now_playing_track_color_options(false), {
			label = {
				max_chars = 40,
				string = "Not Playing",
			},
			padding_left = 0,
			padding_right = 10,
			position = "left",
			scroll_texts = true,
		}),
	},
	RESOURCES = {
		-- Stats mirror aliases: the graph/visual, plus RAM's separate `_state` status
		-- icon. Each renders a live Stats menu-bar item, which Stats colors — so no
		-- color override here.
		ALIAS = alias_opts,
		-- SF Symbol icon per widget, in the live theme foreground. The Stats theme handler repaints
		-- these on a light/dark switch (see event/handlers/resources.lua).
		CPU_ICON = utils.merge(colorschemes.get_default_color_options(), resource_opts, {
			icon = { string = icon.RESOURCES.CPU },
		}),
		GPU_ICON = utils.merge(colorschemes.get_default_color_options(), resource_opts, {
			icon = { string = icon.RESOURCES.GPU },
		}),
		RAM_ICON = utils.merge(colorschemes.get_default_color_options(), resource_opts, {
			icon = { string = icon.RESOURCES.RAM },
		}),
		SENSORS_ICON = utils.merge(colorschemes.get_default_color_options(), resource_opts, {
			icon = { string = icon.RESOURCES.SENSORS },
		}),
	},
	-- Static styling for the per-display space indicators. The handler layers the
	-- per-space colors (from `colorschemes.get_space_color_options`), `position`, and
	-- dynamic strings (number, app glyphs) on top of these at add/set time. Box layout,
	-- left to right: [number │ g1 g2 g3]. Each app glyph is its own item so the inter-icon
	-- gaps can be set with item-level padding; the handler sets every inter-element gap
	-- dynamically (see `glyph_options`). The frontmost-app name is NOT shown in the boxes —
	-- it lives in a separate title pill (`APP_ICON` + `APP_TITLE`, the active app's app-font
	-- glyph and its name) that the same handler maintains at the far edge of each bar; a
	-- standalone Apple badge (`APPLE`) sits at the top bar's far-left edge.
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
				height = 28,
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
		-- label — so item-level padding can put a gap *between* the icons (a single
		-- concatenated app-font string renders its glyphs flush against each other, which is
		-- the crowding this avoids). Both gaps are set dynamically per slot (`glyph_options`):
		-- the left gap (`GAP` from the divider for the leading glyph, else the tighter
		-- `ICON_GAP` between consecutive glyphs), then either 0 (another element follows) or
		-- the edge gap (this glyph ends the box).
		-- Item-level paddings are intentionally omitted here: the handler always sets both,
		-- and a static value would shadow the dynamic one in the first-wins merge.
		GLYPH = {
			icon = { font = font.DEFAULT.APP_ICON },
			label = { drawing = false },
		},
		-- Apple-logo badge pill, a standalone singleton at the top bar's far-left edge (the external
		-- bar omits it): the SF Symbol apple logo (U+1008FA, SF Pro — the app-font has no standalone
		-- Apple glyph) in its own box. `apple_icon_options` colors the glyph with the surface fill the
		-- other pills use; `apple_bracket_options` fills the box with the mauve accent.
		-- `padding_left`/`padding_right` are the 10px inner margins.
		APPLE = {
			icon = {
				string = "\u{1008FA}",
				font = font.DEFAULT.APPLE,
			},
			label = { drawing = false },
			padding_left = 10,
			padding_right = 10,
		},
		-- Trailing spacer after the Apple badge: the gap from its mauve box to the now-playing pill
		-- that follows it in the top bar's `"left"` region. 10px — the same inter-pill gap the Stats
		-- and clock pills use — so the badge sits a uniform step from its neighbour. The following
		-- pill's own inner `padding_*` is its margin, NOT part of this gap (so this spacer alone is the
		-- full gap). Its own spacer, not the 5px box SPACER, so it tunes without touching the space
		-- boxes.
		APPLE_SPACER = {
			drawing = true,
			icon = { drawing = false },
			label = { drawing = false },
			padding_left = 0,
			padding_right = 0,
			width = 10,
		},
		-- Title pill, icon half: the active app's sketchybar-app-font glyph (same source as the
		-- space-box glyphs). `app_icon_options` layers on the glyph string and foreground color.
		-- `padding_left` is the pill's inner left margin (10px), `padding_right` the 5px gap to the
		-- name. The pill sits at the bar's far edge — not one of the per-space boxes.
		APP_ICON = {
			icon = {
				font = font.DEFAULT.APP_ICON,
			},
			label = { drawing = false },
			padding_left = 10,
			padding_right = 5,
		},
		-- Title pill, name half: the macOS frontmost app's name in bold SF Pro
		-- Display. `padding_left` is 0 (the app-icon half owns the 5px gap to the name);
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
