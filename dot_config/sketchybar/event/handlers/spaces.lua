local sbar = require("sketchybar")

local app_icons = require("helpers.app_icons")
local colorschemes = require("helpers.colorschemes")
local font = require("constants.font")
local item = require("constants.item")
local mru = require("model.mru")
local option = require("constants.option")
local utils = require("helpers.utils")

--- Per-display space indicators. One instance of this module runs in each sketchybar
--- process (top bar / external bar); module-level state persists across triggers
--- because the SbarLua event loop keeps the Lua process alive. Each instance renders
--- only the spaces on its own yabai display, querying yabai on every `spaces_change`.
--- @class SpacesManager
local M = {}

--- yabai display index this instance renders (1 = built-in/top, 2 = external). Set by
--- the init profile before `plugins.spaces` fires the first render.
--- @type integer
M.DISPLAY = 1

--- sketchybar position region for this instance's row of space boxes — the right-hand
--- region when the row is split across the notch (see `M.POSITION_LEFT`). The external
--- bar uses `"center"`; the top bar uses `"e"` (the notch-aware "right of notch" region),
--- which anchors the row against the built-in display's notch using the bar's
--- `notch_width` — see `init/topbar.lua`.
--- @type string
M.POSITION = "left"

--- Optional second region for splitting the row across the notch. When set, the title pill
--- plus the first `floor(n/2)` spaces (by sorted index) render here and the rest at
--- `M.POSITION`, so the two sides balance around the notch including the pill; when `nil` the
--- whole row renders at `M.POSITION` (no split). The top bar uses `"q"` (notch-aware
--- "left of notch") to flank the notch with `M.POSITION = "e"`; the external bar leaves it
--- `nil` (no notch). Because `"q"` stacks right-to-left, left-side boxes are added in reverse
--- so they read the same left-to-right as the right side — see `M.render`.
--- @type string?
M.POSITION_LEFT = nil

--- sketchybar position region for the title pill (active app's icon glyph + name). The
--- external bar uses `"center"` — the same region as its space row, with the pill added
--- first so it is the left-most pill in the centered cluster. The top bar uses `"q"` (the
--- notch-aware "left of notch" region), mirroring the space row's `"e"` across the notch.
--- Set by the init profile.
--- @type string
M.APP_POSITION = "center"

--- sketchybar position region for the standalone Apple badge, or `nil` to omit it. The top
--- bar places the badge in the far-left `"left"` region (before the now-playing pill, which is
--- added to that region after it), separate from the title pill's notch group; the external
--- bar leaves this `nil`, so only the title pill renders there. Set by the init profile.
--- @type string?
M.APPLE_POSITION = nil

--- Sorted list of space indices currently materialized as sketchybar items.
--- @type integer[]
M.RENDERED = {}

--- Last-rendered active (visible) flag per space, so a theme repaint needs no query.
--- @type table<integer, boolean>
M.ACTIVE = {}

--- Number of glyph items currently materialized per space. The glyph count is variable
--- (every app with a window is shown), so this lets a structural rebuild remove exactly
--- the right glyphs and lets the diff detect when a space's app count changes.
--- @type table<integer, integer>
M.GLYPH_COUNT = {}

--- Whether a debounced render is already scheduled (coalesces signal bursts). Held true across
--- the entire async render so a second render can't start mid-flight (see M.spaces_change_handler).
--- @type boolean
M.pending = false

--- Set when a spaces_change arrives while a render is scheduled/in-flight; triggers exactly one
--- follow-up render after the current one finishes so a mid-render signal is not lost.
--- @type boolean
M.dirty = false

--- Whether the title-pill items have been created yet. On the external bar the pill is a
--- singleton created once at init; on the split top bar `M.render` re-adds it after the
--- left-of-notch spaces on each structural change to keep it left-most (see `build_title_pill`).
--- @type boolean
M.app_built = false

--- Whether the standalone Apple badge has been created — only on bars that set
--- `M.APPLE_POSITION` (the top bar). The title/theme updaters skip the badge's items on bars
--- that omit it (the external bar), where they were never added.
--- @type boolean
M.apple_built = false

--- Last resolved active-app name for this display's pill. Tracked so a structural rebuild
--- (which re-creates the pill empty) can restore it, and so an unresolvable visible space
--- keeps the last app rather than blanking the pill.
--- @type string
M.app_title = ""

--- Debounce window (seconds) used to coalesce a burst of yabai signals into one render.
local DEBOUNCE = 0.05

--- Shell command for the macOS frontmost app's display name. Used to label an empty
--- focused space with the app macOS auto-selects there (Finder) — see `M.render`.
local FRONT_APP_CMD = 'lsappinfo info -only name "$(lsappinfo front)"'

--- Uniform inner padding (px) for a space box: the gap from the left border to the number,
--- between every element (number, divider, glyphs), and from the last element to the right
--- border are all this value, so the box reads as evenly spaced throughout.
local EDGE_GAP = 10

--- Inter-element gap (px) inside a box: between the number and divider, and between the
--- divider and the first glyph. Equal to `EDGE_GAP` so those gaps match the box's borders.
local GAP = EDGE_GAP

--- Tighter gap (px) between consecutive app-icon glyphs, so a run of app icons reads as a
--- single cluster rather than spaced as widely as the number/divider. Only the gap *between*
--- icons uses this; the divider-to-first-icon gap stays `GAP` (see `glyph_options`).
local ICON_GAP = 5

--- Build the fixed sketchybar item names for a space index. `spacer_l`/`spacer_r` are
--- standalone items (not bracket members) that pad the box on each side; `num` and `div`
--- (number, divider) are bracket members; `bracket` is the box. The app glyphs are variable
--- in number and named separately via `glyph_name`.
--- @param index integer yabai space index
--- @return { spacer_l: string, num: string, div: string, spacer_r: string, bracket: string }
local function names(index)
	local base = item.SPACES.PREFIX .. index
	return {
		spacer_l = base .. ".spacer_l",
		num = base .. ".num",
		div = base .. ".div",
		spacer_r = base .. ".spacer_r",
		bracket = base .. ".bracket",
	}
end

--- Name of the `i`-th app glyph item for a space (1 = leading/active app). The glyph count
--- is variable (one per app with a window), so glyphs are named on demand rather than fixed.
--- @param index integer yabai space index
--- @param i integer glyph slot (1-based)
--- @return string
local function glyph_name(index, i)
	return item.SPACES.PREFIX .. index .. ".g" .. i
end

--- Look up the app-font ligature for every app name (no cap — all of a space's apps are
--- shown). Returns a list (not a concatenated string) so the caller can give each glyph its
--- own item, with the leading glyph styled differently from the rest.
--- @param apps string[] app names, most-recent first
--- @return string[] glyphs list of ":glyph:" ligatures, most-recent first (empty when none)
local function glyphs_for(apps)
	local parts = {}
	for i = 1, #apps do
		parts[i] = app_icons.lookup(apps[i])
	end
	return parts
end

--- Parse the frontmost app name out of `lsappinfo`'s `"LSDisplayName"="Finder"` line.
--- @param raw string|table the command output (a string; non-JSON, so never a table)
--- @return string app name, or "" if it could not be parsed
local function parse_front_app(raw)
	if type(raw) ~= "string" then
		return ""
	end
	return raw:match('"([^"]+)"%s*$') or ""
end

--- Bracket options: static box geometry plus the active/inactive background colors.
--- @param space_colors table from `colorschemes.get_space_color_options`
--- @return table
local function bracket_options(space_colors)
	return utils.merge(option.SPACES.BRACKET, { background = space_colors.background })
end

--- Number-item options: static styling plus the index string, fg color, a bold font on
--- the active space (so the current space's number stands out), the left-border padding,
--- and an item-level right padding that is the inter-element gap to the divider when the
--- space has apps, or the box edge gap when it is empty (keeping an empty box symmetric).
--- Both paddings are `EDGE_GAP`/`GAP` (all 10px). `position` is intentionally omitted — it
--- is an add-time concern (re-`set`ting it re-inserts the item at the end of its region and
--- would shuffle the box order on every refresh).
--- @param index integer space index
--- @param active boolean whether this is the display's visible (current) space
--- @param has_apps boolean whether the space has any glyphs (sets the right gap)
--- @param space_colors table from `colorschemes.get_space_color_options`
--- @return table
local function num_options(index, active, has_apps, space_colors)
	return utils.merge(option.SPACES.NUM, {
		padding_left = EDGE_GAP,
		padding_right = has_apps and GAP or EDGE_GAP,
		icon = utils.merge({
			string = tostring(index),
			font = active and font.DEFAULT.BOLD_LABEL or font.DEFAULT.ICON,
		}, space_colors.icon),
	})
end

--- Divider-item options: the hairline's color follows the fg, and the whole item is
--- shown only when the space has glyphs (so an empty space shows just its number).
--- Visibility is gated on the item-level `drawing`, NOT `background.drawing`: sketchybar
--- implicitly re-enables `background.drawing` whenever `background.color` is set, so
--- toggling `background.drawing` here would be immediately undone by the color we set
--- alongside it (and later by `theme_change_handler`'s recolor), leaving the hairline
--- stuck on for empty spaces. The item's own `drawing` flag is immune to that. `position`
--- is omitted for the same reason as `num_options`.
--- @param has_apps boolean whether the space has any glyphs to divide from the number
--- @param space_colors table from `colorschemes.get_space_color_options`
--- @return table
local function div_options(has_apps, space_colors)
	return utils.merge(option.SPACES.DIVIDER, {
		drawing = has_apps,
		background = { color = space_colors.icon.color },
	})
end

--- Glyph-item options: one MRU app's icon for a glyph slot (`g1`/`g2`/`g3`), or hidden
--- when the slot is unused. `padding_left` is the gap from whatever precedes the glyph: the
--- leading glyph takes the full `GAP` from the divider, while each later glyph takes the
--- tighter `ICON_GAP` from the previous glyph (which leaves its own right padding at 0);
--- `padding_right` is the box edge gap when this glyph is the box's last drawn
--- element, else 0. Hidden via its own `drawing` so an unused slot collapses (padding
--- included) — a still-drawn empty item would hold the bracket open. `dim` colors the glyph
--- with the dimmer foreground instead of the normal one — used for the active space's
--- non-leading app glyphs (apps other than the focused one). `position` is omitted for the
--- same reason as `num_options`.
--- @param glyph string ":glyph:" ligature ("" to hide the slot)
--- @param is_first boolean whether this is the leading glyph (its gap is from the divider, not another icon)
--- @param is_last boolean whether this glyph is the box's last drawn element
--- @param space_colors table from `colorschemes.get_space_color_options`
--- @param dim boolean? color the glyph with the dimmer foreground instead of the normal one
--- @return table
local function glyph_options(glyph, is_first, is_last, space_colors, dim)
	local shown = glyph ~= ""
	local color = dim and space_colors.dim or space_colors.icon
	return utils.merge(option.SPACES.GLYPH, {
		drawing = shown,
		padding_left = shown and (is_first and GAP or ICON_GAP) or 0,
		padding_right = is_last and EDGE_GAP or 0,
		icon = utils.merge({ string = glyph, drawing = shown }, color),
	})
end

--- Title-pill icon options: the active app's app-font glyph in the knockout colour (the bar's
--- own background), matching the Apple badge — the title pill is a mauve "system" pill too.
--- @param glyph string the sketchybar-app-font ligature for the active app (e.g. `:ghostty:`)
--- @return table
local function app_icon_options(glyph)
	return utils.merge(option.SPACES.APP_ICON, {
		icon = { string = glyph, color = colorschemes.get_bar_background() },
	})
end

--- Apple-badge icon options: the Apple glyph in the bar's own background colour (a knockout), so
--- it reads as a cutout in the mauve badge — via `get_bar_background`, tracking the live theme.
--- @return table
local function apple_icon_options()
	return utils.merge(option.SPACES.APPLE, {
		icon = { color = colorschemes.get_bar_background() },
	})
end

--- System-pill bracket options (the Apple badge and the title pill): a solid box filled and
--- bordered with the mauve accent, distinguishing the system pills from the surface space pills.
--- @param space_colors table from `colorschemes.get_space_color_options`
--- @return table
local function apple_bracket_options(space_colors)
	-- `border_color` is the active pill's mauve border (the `ACTIVE_SPACE_BORDER` role) — reused
	-- here as the badge's fill, so the Apple badge is a solid mauve box. No new color.
	local mauve = space_colors.background.border_color
	return utils.merge(option.SPACES.BRACKET, { background = { color = mauve, border_color = mauve } })
end

--- Title-pill name options: the front-app name in the knockout colour (the bar's own
--- background), matching the Apple badge.
--- @param front_app string macOS frontmost app name
--- @return table
local function app_title_options(front_app)
	return utils.merge(option.SPACES.APP_TITLE, {
		label = { string = front_app, color = colorschemes.get_bar_background() },
	})
end

--- Update the active-app pill content and colors: the title pill's app-icon glyph + name and,
--- on bars that have it, the standalone Apple badge (static glyph in a mauve box) — all from
--- the active (mauve) palette. `app` is this display's active app (the leading app of its
--- visible space — see `M.render`), so the title icon matches that space's first glyph; "" hides
--- the pill. The items are created by `M.setup_app_pill`, so this only `set`s and is a no-op
--- until that has run.
--- @param app string this display's active app name ("" hides the pill)
--- @return nil
local function update_app_title(app)
	if not M.app_built then
		return
	end
	local colors = colorschemes.get_space_color_options(true)
	local shown = app ~= ""
	local glyph = shown and app_icons.lookup(app) or ""
	-- Apple badge (only on bars that have it): a standalone, always-drawn system badge — a
	-- static Apple glyph in a mauve box, shown regardless of whether an active app resolves.
	if M.apple_built then
		sbar.set(item.SPACES.APPLE, utils.merge({ drawing = true }, apple_icon_options()))
		sbar.set(item.SPACES.APPLE_BRACKET, utils.merge({ drawing = true }, apple_bracket_options(colors)))
	end
	-- Title pill: a mauve "system" pill — the active app's glyph + name in the knockout colour.
	sbar.set(item.SPACES.APP_ICON, utils.merge({ drawing = shown }, app_icon_options(glyph)))
	sbar.set(item.SPACES.APP_TITLE, utils.merge({ drawing = shown }, app_title_options(app)))
	sbar.set(item.SPACES.APP_BRACKET, utils.merge({ drawing = shown }, apple_bracket_options(colors)))
end

--- Add the standalone Apple badge to `M.APPLE_POSITION` (the top bar's far-left `"left"` region):
--- the mauve badge box followed by a trailing spacer giving the gap to the next pill the profile
--- adds to that region after it (the now-playing pill). A create-once singleton —
--- it shares no region with the space boxes, so (unlike the title pill) `M.render` never re-adds
--- it. Content starts hidden and is filled by `update_app_title`. Only called when
--- `M.APPLE_POSITION` is set (`M.setup_app_pill`).
--- @return nil
local function build_apple_badge()
	local colors = colorschemes.get_space_color_options(true)
	local pos = M.APPLE_POSITION
	local hidden = { drawing = false }
	sbar.add("item", item.SPACES.APPLE, utils.merge({ position = pos }, utils.merge(hidden, apple_icon_options())))
	-- Trailing spacer: the gap from the badge to the now-playing pill that follows it in `"left"`.
	sbar.add("item", item.SPACES.APPLE_SPACER, utils.merge({ position = pos }, option.SPACES.APPLE_SPACER))
	sbar.add(
		"bracket",
		item.SPACES.APPLE_BRACKET,
		{ item.SPACES.APPLE },
		utils.merge(hidden, apple_bracket_options(colors))
	)
end

--- (Re)add the title pill (the active app's icon glyph + name) to `M.APP_POSITION`, with a
--- trailing 5px spacer giving the same 10px gap to the first space box as the boxes have between
--- them. The title pill leads its region (the external centered row, or the top bar's left-of-notch
--- `"q"` group), so it has no leading spacer — its left edge is the cluster's edge. The two items
--- are added in reverse on the notch's right-to-left `"q"` region so they read the same left-to-right
--- as on the external bar (padding is in visual space). Content starts hidden and is filled by
--- `update_app_title`. Factored out of `M.setup_app_pill` so `M.render` can re-add the pill after the
--- left-of-notch spaces — which are themselves re-added on every structural change — keeping it the
--- left-most item on the split top bar.
--- @return nil
local function build_title_pill()
	local colors = colorschemes.get_space_color_options(true)
	local pos = M.APP_POSITION
	local hidden = { drawing = false }
	-- Visual left-to-right sequence: [app icon][app name] [gap to spaces].
	local seq = {
		{ item.SPACES.APP_ICON, utils.merge(hidden, app_icon_options("")) },
		{ item.SPACES.APP_TITLE, utils.merge(hidden, app_title_options("")) },
		{ item.SPACES.APP_SPACER, option.SPACES.SPACER },
	}
	local from, to, step = 1, #seq, 1
	if pos == "q" then
		from, to, step = #seq, 1, -1
	end
	for j = from, to, step do
		sbar.add("item", seq[j][1], utils.merge({ position = pos }, seq[j][2]))
	end
	sbar.add(
		"bracket",
		item.SPACES.APP_BRACKET,
		{ item.SPACES.APP_ICON, item.SPACES.APP_TITLE },
		utils.merge(hidden, apple_bracket_options(colors))
	)
end

--- Remove the title-pill items, so `M.render` can re-add (reposition) the pill after the
--- left-of-notch spaces on a structural rebuild. The standalone Apple badge is left untouched —
--- it lives in its own region (the top bar's `"left"`) and is not part of the notch rebuild.
--- @return nil
local function remove_title_pill()
	sbar.remove(item.SPACES.APP_BRACKET)
	sbar.remove(item.SPACES.APP_ICON)
	sbar.remove(item.SPACES.APP_TITLE)
	sbar.remove(item.SPACES.APP_SPACER)
end

--- Create the active-app pill items once at init, at the point in the profile's add sequence where
--- the title pill should sit among items sharing its region — before `now_playing` on the external
--- bar, so it leads the centered cluster. On the split top bar the title pill must follow the left
--- spaces, so `M.render` re-adds it after them (see `build_title_pill`). The standalone Apple badge
--- (top bar only — when `M.APPLE_POSITION` is set) is created here too and never re-added.
--- @return nil
function M.setup_app_pill()
	if M.APPLE_POSITION then
		build_apple_badge()
		M.apple_built = true
	end
	build_title_pill()
	M.app_built = true
end

--- Add one space box's items and its bracket in a single region. The items are listed in
--- visual left-to-right order (spacer, number, divider, glyphs, spacer) and added forward for
--- a left-to-right region or in reverse for the notch's right-to-left `"q"` region, so the box
--- reads identically (number left, glyphs right) on both sides — padding is in visual space,
--- so the per-item options are the same either way. The glyph row is one item per app: the
--- last glyph takes the edge gap on its right, the rest leave their right padding at 0 so the
--- next glyph's left padding owns the tighter inter-icon `ICON_GAP` gap; the leading glyph
--- instead takes the full `GAP` from the divider. On the active space the leading glyph keeps
--- the normal foreground; the rest dim.
--- @param b { idx: integer, glyphs: string[], active: boolean }
--- @param position string sketchybar region for this box
--- @param reverse boolean add items right-to-left (for the `"q"` region)
--- @return nil
local function add_box(b, position, reverse)
	local idx, glyphs, active = b.idx, b.glyphs, b.active
	local count = #glyphs
	local has_apps = count > 0
	local space_colors = colorschemes.get_space_color_options(active)
	local n = names(idx)
	-- Visual left-to-right sequence of the box's standalone items.
	local seq = {
		{ n.spacer_l, option.SPACES.SPACER },
		{ n.num, num_options(idx, active, has_apps, space_colors) },
		{ n.div, div_options(has_apps, space_colors) },
	}
	for i = 1, count do
		seq[#seq + 1] =
			{ glyph_name(idx, i), glyph_options(glyphs[i], i == 1, i == count, space_colors, active and i > 1) }
	end
	seq[#seq + 1] = { n.spacer_r, option.SPACES.SPACER }
	local from, to, step = 1, #seq, 1
	if reverse then
		from, to, step = #seq, 1, -1
	end
	for j = from, to, step do
		sbar.add("item", seq[j][1], utils.merge({ position = position }, seq[j][2]))
	end
	-- Bracket members are order-independent (the box is drawn behind them).
	local members = { n.num, n.div }
	for i = 1, count do
		members[#members + 1] = glyph_name(idx, i)
	end
	sbar.add("bracket", n.bracket, members, bracket_options(space_colors))
	M.GLYPH_COUNT[idx] = count
end

--- Update one already-materialized space box in place (no add/remove, so its region and order
--- are untouched). Used on a non-structural refresh — same glyph count, content and colors only.
--- @param b { idx: integer, glyphs: string[], active: boolean }
--- @return nil
local function set_box(b)
	local idx, glyphs, active = b.idx, b.glyphs, b.active
	local count = #glyphs
	local has_apps = count > 0
	local space_colors = colorschemes.get_space_color_options(active)
	local n = names(idx)
	sbar.set(n.num, num_options(idx, active, has_apps, space_colors))
	sbar.set(n.div, div_options(has_apps, space_colors))
	for i = 1, count do
		sbar.set(glyph_name(idx, i), glyph_options(glyphs[i], i == 1, i == count, space_colors, active and i > 1))
	end
	sbar.set(n.bracket, bracket_options(space_colors))
	M.GLYPH_COUNT[idx] = count
end

--- Query yabai (and the frontmost app) and (re)paint this display's space boxes. Runs
--- three nested async queries; all add/set/remove calls in the inner callback commit as
--- one sketchybar transaction, so even a structural rebuild does not flicker.
--- @param done fun()? invoked once the async render completes (on every exit path)
--- @return nil
function M.render(done)
	sbar.exec("yabai -m query --spaces", function(spaces)
		if type(spaces) ~= "table" then
			if done then
				done()
			end
			return
		end
		sbar.exec("yabai -m query --windows", function(windows)
			if type(windows) ~= "table" then
				if done then
					done()
				end
				return
			end
			sbar.exec(FRONT_APP_CMD, function(front_raw)
				local front_app = parse_front_app(front_raw)

				-- This display's active app — the leading app of its visible space, captured
				-- in the render loop below. Drives the per-display app pill (in sync with that
				-- space's first glyph), rather than the global frontmost app.
				local display_title = ""

				-- Group apps by space (first-seen order, deduped) and promote the focused
				-- app on this display to the front of its space's MRU.
				local apps_by_space, seen, any_app = {}, {}, {}
				for _, w in ipairs(windows) do
					local s, app = w.space, w.app
					if s and app then
						any_app[app] = true
						apps_by_space[s] = apps_by_space[s] or {}
						seen[s] = seen[s] or {}
						if not seen[s][app] then
							seen[s][app] = true
							apps_by_space[s][#apps_by_space[s] + 1] = app
						end
						if w["has-focus"] and w.display == M.DISPLAY then
							mru.promote(s, app)
						end
					end
				end

				-- This display's spaces, sorted by index.
				local my = {}
				for _, sp in ipairs(spaces) do
					if sp.display == M.DISPLAY then
						my[#my + 1] = sp
					end
				end
				table.sort(my, function(a, b)
					return a.index < b.index
				end)

				-- First pass: reconcile each space's MRU and compute its glyph list, active
				-- flag, and (for the visible space) the per-display pill title. mru.reconcile
				-- updates the model as a side effect, so it runs exactly once per space here.
				local boxes = {}
				for _, sp in ipairs(my) do
					local idx = sp.index
					local recents = mru.reconcile(idx, apps_by_space[idx] or {})
					local active = sp["is-visible"] == true
					local focused = sp["has-focus"] == true
					M.ACTIVE[idx] = active
					-- A windowless macOS front app on the focused space (Finder on a desktop
					-- click, or an empty space) names the pill but is NOT shown as a box glyph;
					-- the box shows only apps with windows (the MRU). Borrow front_app only when it owns no
					-- window anywhere (any_app), never one whose window is on another display.
					local leading_app = recents[1] or ""
					if focused and front_app ~= "" and not any_app[front_app] then
						leading_app = front_app
					end
					if active then
						display_title = leading_app
					end
					boxes[#boxes + 1] = { idx = idx, glyphs = glyphs_for(recents), active = active }
				end

				-- Structural diff: rebuild when the set of space indices OR any space's glyph
				-- count changes. Both shift item positions in the region (a new item is added at
				-- the end), which an in-place sbar.set cannot fix; a reorder or restring of the
				-- same glyph count is non-structural and updates in place.
				local indices = {}
				for i, b in ipairs(boxes) do
					indices[i] = b.idx
				end
				local structural = #indices ~= #M.RENDERED
				if not structural then
					for i = 1, #indices do
						if indices[i] ~= M.RENDERED[i] then
							structural = true
							break
						end
					end
				end
				if not structural then
					for _, b in ipairs(boxes) do
						if (M.GLYPH_COUNT[b.idx] or 0) ~= #b.glyphs then
							structural = true
							break
						end
					end
				end

				-- On a structural change, tear down every previously-rendered space (each item
				-- by name; sbar.remove takes one at a time, and cached M.GLYPH_COUNT says how
				-- many glyph items each old space had).
				if structural then
					for _, idx in ipairs(M.RENDERED) do
						local n = names(idx)
						sbar.remove(n.bracket)
						sbar.remove(n.spacer_l)
						sbar.remove(n.num)
						sbar.remove(n.div)
						for i = 1, M.GLYPH_COUNT[idx] or 0 do
							sbar.remove(glyph_name(idx, i))
						end
						sbar.remove(n.spacer_r)
					end
				end

				-- Paint the boxes. When the row is split across the notch (M.POSITION_LEFT set),
				-- the left region holds the title pill plus the first `floor(n/2)` spaces and the
				-- right holds the rest, so the two sides balance around the notch *including* the
				-- pill. On a structural rebuild the left boxes are added in reverse so they read the
				-- same left-to-right as the right side despite `"q"` stacking right-to-left. A
				-- non-structural refresh just updates each box in place (region/order untouched).
				if structural then
					-- The title pill is one "system pill", so the left already carries one item before
					-- any spaces. Give it floor(n/2) spaces so the two sides balance *including* the
					-- pill — left items (incl. pill) vs right go (1,1), (2,1), (2,2), (3,2), (3,3),
					-- (4,3)… (The standalone Apple badge sits in the far-left `"left"` region, not this
					-- notch group, so it is not part of the split.)
					local left_n = M.POSITION_LEFT and math.floor(#boxes / 2) or 0
					for i = left_n, 1, -1 do
						add_box(boxes[i], M.POSITION_LEFT, true)
					end
					-- Keep the pill left-most: `"q"` appends leftward, and the left spaces were just
					-- (re)added there, so the previously-added pill is no longer the outermost item.
					-- Re-add it after them — only when it shares the left region (the split top bar).
					if M.app_built and M.POSITION_LEFT and M.APP_POSITION == M.POSITION_LEFT then
						remove_title_pill()
						build_title_pill()
					end
					for i = left_n + 1, #boxes do
						add_box(boxes[i], M.POSITION, false)
					end
				else
					for _, b in ipairs(boxes) do
						set_box(b)
					end
				end

				-- Active-app pill: this display's visible-space leading app (captured in the
				-- loop). Updated in this same transaction so it commits without flicker alongside
				-- the boxes. `M.app_title` holds the last resolved app: a structural rebuild on the
				-- split top bar re-creates the pill empty (see the box loop above), and an
				-- unresolvable visible space — e.g. a Finder desktop (no window) on a display that
				-- just lost focus — has no title; both fall back to it, so the pill keeps its last
				-- app rather than vanishing out from under the active space.
				if display_title ~= "" then
					M.app_title = display_title
				end
				update_app_title(M.app_title)

				M.RENDERED = indices

				-- Forget MRU/active state for spaces no longer on this display.
				local live = {}
				for _, idx in ipairs(indices) do
					live[idx] = true
				end
				mru.prune(live)
				for idx in pairs(M.ACTIVE) do
					if not live[idx] then
						M.ACTIVE[idx] = nil
					end
				end
				for idx in pairs(M.GLYPH_COUNT) do
					if not live[idx] then
						M.GLYPH_COUNT[idx] = nil
					end
				end

				if done then
					done()
				end
			end)
		end)
	end)
end

--- Subscribed to `spaces_change`. Coalesces a burst of yabai signals (window drags,
--- app switches) into a single trailing-edge render so the fan-out to both bars stays
--- cheap; the deferred query reflects the latest yabai state at run time.
--- @return nil
function M.spaces_change_handler()
	if M.pending then
		-- A render is already scheduled or in flight; remember the signal so exactly one more
		-- render runs after it rather than overlapping it (two concurrent renders read the same
		-- stale M.RENDERED and double-remove / re-add the same items).
		M.dirty = true
		return
	end
	M.pending = true
	M.dirty = false
	sbar.delay(DEBOUNCE, function()
		-- Hold M.pending across the whole async render (three nested yabai queries), clearing it
		-- only in the completion callback; a signal arriving meanwhile sets M.dirty and triggers a
		-- single trailing render.
		M.render(function()
			M.pending = false
			if M.dirty then
				M.spaces_change_handler()
			end
		end)
	end)
end

--- Repaint every live space box from the refreshed palette using the cached active
--- flags (no yabai query). The caller refreshes the palette first.
--- @return nil
function M.theme_change_handler()
	for _, idx in ipairs(M.RENDERED) do
		local active = M.ACTIVE[idx] == true
		local space_colors = colorschemes.get_space_color_options(active)
		local n = names(idx)
		sbar.set(n.bracket, { background = space_colors.background })
		sbar.set(n.num, { icon = space_colors.icon })
		sbar.set(n.div, { background = { color = space_colors.icon.color } })
		-- Active space: leading glyph uses the normal fg, the other apps the dimmer
		-- fg. Inactive spaces use the fg (already the dim overlay1) for every glyph.
		for i = 1, M.GLYPH_COUNT[idx] or 0 do
			sbar.set(glyph_name(idx, i), { icon = (active and i > 1) and space_colors.dim or space_colors.icon })
		end
	end

	-- Recolor the active-app pill from the refreshed palette (always the "active" mauve
	-- treatment). Guarded — `theme_change` can fire before the first render builds it.
	if M.app_built then
		local app_colors = colorschemes.get_space_color_options(true)
		local mauve = app_colors.background.border_color
		local knockout = colorschemes.get_bar_background()
		-- System pills: knockout glyph/text on a mauve box. The Apple badge only on bars that have it.
		if M.apple_built then
			sbar.set(item.SPACES.APPLE, { icon = { color = knockout } })
			sbar.set(item.SPACES.APPLE_BRACKET, { background = { color = mauve, border_color = mauve } })
		end
		sbar.set(item.SPACES.APP_ICON, { icon = { color = knockout } })
		sbar.set(item.SPACES.APP_TITLE, { label = { color = knockout } })
		sbar.set(item.SPACES.APP_BRACKET, { background = { color = mauve, border_color = mauve } })
	end
end

return M
