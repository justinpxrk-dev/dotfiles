local asset = require("constants.asset")
local catppuccin = require("catppuccin")
local themes = require("helpers.themes")

--- @class Colorschemes
--- @alias ColorschemePalette table<ColorschemePaletteOption, integer>
--- @alias ColorschemePaletteOption "ACTIVE_SPACE_BG" | "ACTIVE_SPACE_BORDER" | "ACTIVE_SPACE_FG" | "BACKGROUND" | "ICON" | "INACTIVE_LABEL" | "INACTIVE_SPACE_BG" | "INACTIVE_SPACE_BORDER" | "INACTIVE_SPACE_FG" | "LABEL"
local M = {}

--- Map a Catppuccin flavor palette (from the `catppuccin` LuaRocks module) to the
--- bar's semantic color roles. Translucent surfaces (background, the inactive space box's
--- fill and border) keep the 0xf2 alpha the bar used previously; foreground roles — including
--- the dim `overlay1` (`INACTIVE_LABEL`/`INACTIVE_SPACE_FG`) — are fully opaque. Palette colors
--- are objects, so the hex is read via `.hex`.
---
--- The space-box roles drive the per-display space indicators: every box is a dim
--- translucent `surface0` fill. The visible (active) space has a `mauve` border and bright
--- `text` number/glyphs with its leading app glyph in `mauve`; inactive boxes have a dim
--- `surface1` border and a dimmer `overlay1` foreground. The mauve (active border + glyph
--- accent) is the only role meant to flip with light/dark on a dark-pinned bar — see
--- `get_space_color_options`'s `pin_dark_chrome`.
--- @param p table a Catppuccin flavor palette, e.g. `catppuccin.mocha()`
--- @return ColorschemePalette
local function roles(p)
	return {
		ACTIVE_SPACE_BG = themes.hex_to_color(p.surface0.hex, 0xf2),
		ACTIVE_SPACE_BORDER = themes.hex_to_color(p.mauve.hex),
		ACTIVE_SPACE_FG = themes.hex_to_color(p.text.hex),
		BACKGROUND = themes.hex_to_color(p.base.hex, 0xf2),
		ICON = themes.hex_to_color(p.text.hex),
		INACTIVE_LABEL = themes.hex_to_color(p.overlay1.hex),
		INACTIVE_SPACE_BG = themes.hex_to_color(p.surface0.hex, 0xf2),
		INACTIVE_SPACE_BORDER = themes.hex_to_color(p.surface1.hex, 0xf2),
		INACTIVE_SPACE_FG = themes.hex_to_color(p.overlay1.hex),
		LABEL = themes.hex_to_color(p.text.hex),
	}
end

--- The active palette, re-derived from the system theme by `M.refresh()`.
--- @type ColorschemePalette
local colors = roles(catppuccin.latte())

--- The always-dark (Mocha) palette, never refreshed. Used for the dim "chrome" of bars
--- whose background is pinned dark regardless of the system theme (the black top bar), so
--- those surfaces never turn bright in light mode — see `M.get_space_color_options`'s
--- `pin_dark_chrome`.
--- @type ColorschemePalette
local dark = roles(catppuccin.mocha())

--- Bar background color options.
--- @return table options sketchybar bar `color` override
function M.get_bar_color_options()
	return {
		color = colors.BACKGROUND,
	}
end

--- Default item color options shared by every item's icon and label.
--- @param pin_dark_chrome boolean? color from the always-dark palette instead of the
--- live theme — for items on a bar whose background is pinned dark (the top bar's
--- resource icons), so they never flip to a light color in light mode.
--- @return table options sketchybar `icon` and `label` color overrides
function M.get_default_color_options(pin_dark_chrome)
	local chrome = pin_dark_chrome and dark or colors
	return {
		label = {
			color = chrome.LABEL,
		},
		icon = {
			color = chrome.ICON,
		},
	}
end

--- Now Playing artwork placeholder options. Picks the transparent logo image, shown when no
--- real track artwork is available. Tracks the active theme, or pins the dark-mode logo when
--- `pin_dark_chrome` is set (the black top bar, where the light-mode logo would be invisible).
--- @param pin_dark_chrome boolean? always use the dark-mode logo (for the pinned-dark top bar)
--- @return table options sketchybar `background.image` override
function M.get_now_playing_artwork_logo_color_options(pin_dark_chrome)
	return {
		background = {
			image = {
				string = pin_dark_chrome and asset.NOW_PLAYING.ARTWORK.DEFAULT_IMAGE_DARK_TRANSPARENT or themes.select(
					asset.NOW_PLAYING.ARTWORK.DEFAULT_IMAGE_DARK_TRANSPARENT,
					asset.NOW_PLAYING.ARTWORK.DEFAULT_IMAGE_LIGHT_TRANSPARENT
				),
			},
		},
	}
end

--- Now Playing track label color options. Uses the active label color while a track is playing
--- and the dimmed inactive color when paused or stopped — from the always-dark palette when
--- `pin_dark_chrome` is set (the black top bar, where the light-mode label would be unreadable).
--- @param playing boolean whether a track is currently playing
--- @param pin_dark_chrome boolean? color from the always-dark palette (for the pinned-dark top bar)
--- @return table options sketchybar `label` color override
function M.get_now_playing_track_color_options(playing, pin_dark_chrome)
	local palette = pin_dark_chrome and dark or colors
	return {
		label = {
			color = playing and palette.LABEL or palette.INACTIVE_LABEL,
		},
	}
end

--- Space-box color options for a single per-display space indicator. Returns the
--- bracket `background` (fill + border) and the member items' `icon`/`label` colors,
--- so the handler can paint the bracket and the number/glyph items in one shape.
---
--- `pin_dark_chrome` is for bars whose background is pinned dark regardless of the system
--- theme (the black top bar): it holds every role except the active space's mauve border on
--- the always-dark Mocha palette, so on that bar only the mauve changes with light/dark —
--- the dark fill, the dim inactive border, and all foreground stay dark. The themed external
--- bar leaves it false and tracks fully. The returned `dim` is the dimmer foreground
--- (`overlay1`) for the active space's non-leading app glyphs (the apps other than the
--- focused one). Inactive spaces use a dim `surface1` border (no mauve).
--- @param active boolean whether this is the display's visible (current) space
--- @param pin_dark_chrome boolean? keep every role but the active mauve border on the dark palette
--- @return table options sketchybar `background`, `icon`, `label`, and `dim` color overrides
function M.get_space_color_options(active, pin_dark_chrome)
	local chrome = pin_dark_chrome and dark or colors
	-- Only the active space's mauve border tracks the live theme (the thing meant to flip
	-- with light/dark); the fill, the dim inactive border, and all foreground (including the
	-- dimmer `dim`) follow `chrome` (dark when pinned), so on a dark-backgrounded bar only
	-- the mauve changes.
	local bg = active and chrome.ACTIVE_SPACE_BG or chrome.INACTIVE_SPACE_BG
	local border = active and colors.ACTIVE_SPACE_BORDER or chrome.INACTIVE_SPACE_BORDER
	local fg = active and chrome.ACTIVE_SPACE_FG or chrome.INACTIVE_SPACE_FG
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
			color = chrome.INACTIVE_SPACE_FG,
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
