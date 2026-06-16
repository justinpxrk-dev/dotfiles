local sbar = require("sketchybar")

local app_icons = require("helpers.app_icons")
local colorschemes = require("helpers.colorschemes")
local font = require("constants.font")
local item = require("constants.item")
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

--- sketchybar position region for this instance's row of space boxes. The external
--- bar uses `"center"`; the top bar uses `"e"` (the notch-aware "right of notch"
--- region), which anchors the row against the built-in display's notch using the
--- bar's `notch_width` — see `init/topbar.lua`.
--- @type string
M.POSITION = "left"

--- sketchybar position region for the active-app pill (Apple glyph + frontmost-app
--- name). The external bar uses `"center"` — the same region as its space row, with the
--- pill added first so it is the left-most pill in the centered cluster. The top bar uses
--- `"q"` (the notch-aware "left of notch" region), mirroring the space row's `"e"` across
--- the notch. Set by the init profile.
--- @type string
M.APP_POSITION = "center"

--- Whether to keep every color but the mauve border/accent on the always-dark palette. Set
--- by the top-bar profile, whose background is pinned black: there only the mauve changes
--- with light/dark, while the dark fill and all text/icons stay dark. The themed external
--- bar leaves it false. See `colorschemes.get_space_color_options`.
--- @type boolean
M.PIN_DARK_CHROME = false

--- Per-space most-recently-focused app order (most-recent first, deduped by app).
--- @type table<integer, string[]>
M.MRU = {}

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

--- Whether a debounced render is already scheduled (coalesces signal bursts).
--- @type boolean
M.pending = false

--- Whether the singleton active-app pill items have been created yet. The pill is
--- created lazily on the first render and only updated thereafter — it is never torn
--- down with the per-space boxes on a structural change.
--- @type boolean
M.app_built = false

--- Debounce window (seconds) used to coalesce a burst of yabai signals into one render.
local DEBOUNCE = 0.05

--- Shell command for the macOS frontmost app's display name. Used to label an empty
--- focused space with the app macOS auto-selects there (Finder) — see `M.render`.
local FRONT_APP_CMD = 'lsappinfo info -only name "$(lsappinfo front)"'

--- Uniform inner padding (px) for a space box: the gap from the left border to the number,
--- between every element (number, divider, glyphs), and from the last element to the right
--- border are all this value, so the box reads as evenly spaced throughout.
local EDGE_GAP = 10

--- Inter-element gap (px) inside a box: between the number and divider, the divider and
--- the first glyph, and consecutive glyphs. Kept equal to `EDGE_GAP` so every gap in the
--- box — borders included — is the same 10px.
local GAP = EDGE_GAP

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

--- Move `app` to the front of space `index`'s MRU list (the app you're now using).
--- @param index integer space index
--- @param app string app name
local function promote(index, app)
	local next_list = { app }
	for _, a in ipairs(M.MRU[index] or {}) do
		if a ~= app then
			next_list[#next_list + 1] = a
		end
	end
	M.MRU[index] = next_list
end

--- Reconcile a space's MRU against the apps currently present in it: keep present apps
--- in their existing recency order, then append newly-present apps (first-seen order)
--- at the back. Apps that have closed drop out.
--- @param index integer space index
--- @param present string[] apps currently in the space, first-seen order
--- @return string[] reconciled MRU, most-recent first
local function reconcile_mru(index, present)
	local present_set = {}
	for _, app in ipairs(present) do
		present_set[app] = true
	end

	local kept, kept_set = {}, {}
	for _, app in ipairs(M.MRU[index] or {}) do
		if present_set[app] and not kept_set[app] then
			kept[#kept + 1] = app
			kept_set[app] = true
		end
	end
	for _, app in ipairs(present) do
		if not kept_set[app] then
			kept[#kept + 1] = app
			kept_set[app] = true
		end
	end

	M.MRU[index] = kept
	return kept
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
--- when the slot is unused. `padding_left` is the inter-element gap from whatever precedes
--- the glyph (the divider or the previous glyph, each of which leaves its own right padding
--- at 0); `padding_right` is the box edge gap when this glyph is the box's last drawn
--- element, else 0. Hidden via its own `drawing` so an unused slot collapses (padding
--- included) — a still-drawn empty item would hold the bracket open. `dim` colors the glyph
--- with the dimmer foreground instead of the normal one — used for the active space's
--- non-leading app glyphs (apps other than the focused one). `position` is omitted for the
--- same reason as `num_options`.
--- @param glyph string ":glyph:" ligature ("" to hide the slot)
--- @param is_last boolean whether this glyph is the box's last drawn element
--- @param space_colors table from `colorschemes.get_space_color_options`
--- @param dim boolean? color the glyph with the dimmer foreground instead of the normal one
--- @return table
local function glyph_options(glyph, is_last, space_colors, dim)
	local shown = glyph ~= ""
	local color = dim and space_colors.dim or space_colors.icon
	return utils.merge(option.SPACES.GLYPH, {
		drawing = shown,
		padding_left = shown and GAP or 0,
		padding_right = is_last and EDGE_GAP or 0,
		icon = utils.merge({ string = glyph, drawing = shown }, color),
	})
end

--- Active-app pill, Apple-icon options: static styling plus the foreground color.
--- @param space_colors table from `colorschemes.get_space_color_options`
--- @return table
local function app_icon_options(space_colors)
	return utils.merge(option.SPACES.APP_ICON, { icon = space_colors.icon })
end

--- Active-app pill, title options: static styling plus the front-app name and fg color.
--- @param front_app string macOS frontmost app name
--- @param space_colors table from `colorschemes.get_space_color_options`
--- @return table
local function app_title_options(front_app, space_colors)
	return utils.merge(option.SPACES.APP_TITLE, {
		label = utils.merge({ string = front_app }, space_colors.label),
	})
end

--- Update the singleton active-app pill's content and colors: the Apple glyph's color,
--- the title's string and color, and the bracket background — all from the active (mauve)
--- palette. `app` is this display's active app (the leading app of its visible space — see
--- `M.render`), so the pill stays in sync with that space's first glyph; "" hides the pill.
--- The pill items are created once at init by `M.setup_app_pill` (so the profile controls
--- their add order, and thus their placement among other same-region items), so this only
--- `set`s and is a no-op until that has run.
--- @param app string this display's active app name ("" hides the pill)
--- @return nil
local function update_app_title(app)
	if not M.app_built then
		return
	end
	local colors = colorschemes.get_space_color_options(true, M.PIN_DARK_CHROME)
	local shown = app ~= ""
	sbar.set(item.SPACES.APP_ICON, utils.merge({ drawing = shown }, app_icon_options(colors)))
	sbar.set(item.SPACES.APP_TITLE, utils.merge({ drawing = shown }, app_title_options(app, colors)))
	sbar.set(item.SPACES.APP_BRACKET, utils.merge({ drawing = shown }, bracket_options(colors)))
end

--- Create the singleton active-app pill (Apple glyph + front-app title in a mauve box).
--- Called once by each init profile at the point in its add sequence where the pill should
--- sit among other items sharing its region — e.g. before `now_playing` on the external
--- bar, so the pill is the left-most `"left"` item. The `"q"` region (top bar, left of
--- notch) stacks right-to-left, so the title is added first (nearest the notch) and the
--- Apple glyph to its left; other regions stack left-to-right, so the Apple glyph leads.
--- Item padding is in visual space (unaffected by add order), so both bars share the same
--- per-item options. Content is filled by the first `render` (the title starts hidden).
--- @return nil
function M.setup_app_pill()
	local colors = colorschemes.get_space_color_options(true, M.PIN_DARK_CHROME)
	local icon, title, bracket = item.SPACES.APP_ICON, item.SPACES.APP_TITLE, item.SPACES.APP_BRACKET
	local icon_opts = utils.merge({ position = M.APP_POSITION }, app_icon_options(colors))
	local title_opts = utils.merge({ position = M.APP_POSITION, drawing = false }, app_title_options("", colors))
	if M.APP_POSITION == "q" then
		sbar.add("item", title, title_opts)
		sbar.add("item", icon, icon_opts)
	else
		sbar.add("item", icon, icon_opts)
		sbar.add("item", title, title_opts)
	end
	sbar.add("bracket", bracket, { icon, title }, bracket_options(colors))
	-- When the pill shares its region with the centered space row (external bar), add a
	-- trailing spacer so the gap from the pill to the first box matches the 10px inter-box
	-- gap (each box carries a 5px spacer; the pill needs its own to contribute the other
	-- half). At `"q"` (top bar) the pill is isolated against the notch, so it gets none — a
	-- spacer there would only push it off the notch edge.
	if M.APP_POSITION == M.POSITION then
		sbar.add("item", item.SPACES.APP_SPACER, utils.merge({ position = M.APP_POSITION }, option.SPACES.SPACER))
	end
	M.app_built = true
end

--- Query yabai (and the frontmost app) and (re)paint this display's space boxes. Runs
--- three nested async queries; all add/set/remove calls in the inner callback commit as
--- one sketchybar transaction, so even a structural rebuild does not flicker.
--- @return nil
function M.render()
	sbar.exec("yabai -m query --spaces", function(spaces)
		if type(spaces) ~= "table" then
			return
		end
		sbar.exec("yabai -m query --windows", function(windows)
			if type(windows) ~= "table" then
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
				local apps_by_space, seen = {}, {}
				for _, w in ipairs(windows) do
					local s, app = w.space, w.app
					if s and app then
						apps_by_space[s] = apps_by_space[s] or {}
						seen[s] = seen[s] or {}
						if not seen[s][app] then
							seen[s][app] = true
							apps_by_space[s][#apps_by_space[s] + 1] = app
						end
						if w["has-focus"] and w.display == M.DISPLAY then
							promote(s, app)
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
				-- flag, and (for the visible space) the per-display pill title. reconcile_mru
				-- updates M.MRU as a side effect, so it runs exactly once per space here.
				local boxes = {}
				for _, sp in ipairs(my) do
					local idx = sp.index
					local mru = reconcile_mru(idx, apps_by_space[idx] or {})
					local active = sp["is-visible"] == true
					local focused = sp["has-focus"] == true
					M.ACTIVE[idx] = active
					-- A windowless macOS front app on the focused space (Finder on a desktop
					-- click, or an empty space) names the pill but is NOT shown as a box glyph;
					-- the box shows only apps with windows (the MRU).
					local front_has_window = seen[idx] ~= nil and seen[idx][front_app] == true
					local leading_app = mru[1] or ""
					if focused and front_app ~= "" and not front_has_window then
						leading_app = front_app
					end
					if active then
						display_title = leading_app
					end
					boxes[#boxes + 1] = { idx = idx, glyphs = glyphs_for(mru), active = active }
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

				for _, b in ipairs(boxes) do
					local idx, glyphs, active = b.idx, b.glyphs, b.active
					local count = #glyphs
					local has_apps = count > 0
					local space_colors = colorschemes.get_space_color_options(active, M.PIN_DARK_CHROME)
					local n = names(idx)
					if structural then
						-- Items added left-to-right; the bracket draws the box behind its members. The
						-- glyph row is one item per app: the last glyph takes the edge gap on its right,
						-- the rest leave their right padding at 0 so the next glyph's left padding owns
						-- the 10px inter-icon gap. On the active space the leading glyph keeps the normal
						-- foreground; the rest dim.
						sbar.add("item", n.spacer_l, utils.merge({ position = M.POSITION }, option.SPACES.SPACER))
						sbar.add(
							"item",
							n.num,
							utils.merge({ position = M.POSITION }, num_options(idx, active, has_apps, space_colors))
						)
						sbar.add(
							"item",
							n.div,
							utils.merge({ position = M.POSITION }, div_options(has_apps, space_colors))
						)
						local members = { n.num, n.div }
						for i = 1, count do
							local gname = glyph_name(idx, i)
							sbar.add(
								"item",
								gname,
								utils.merge(
									{ position = M.POSITION },
									glyph_options(glyphs[i], i == count, space_colors, active and i > 1)
								)
							)
							members[#members + 1] = gname
						end
						sbar.add("item", n.spacer_r, utils.merge({ position = M.POSITION }, option.SPACES.SPACER))
						sbar.add("bracket", n.bracket, members, bracket_options(space_colors))
					else
						sbar.set(n.num, num_options(idx, active, has_apps, space_colors))
						sbar.set(n.div, div_options(has_apps, space_colors))
						for i = 1, count do
							sbar.set(
								glyph_name(idx, i),
								glyph_options(glyphs[i], i == count, space_colors, active and i > 1)
							)
						end
						sbar.set(n.bracket, bracket_options(space_colors))
					end
					M.GLYPH_COUNT[idx] = count
				end

				-- Active-app pill: this display's visible-space leading app (captured in the
				-- loop). Updated in this same transaction so it commits without flicker
				-- alongside the boxes; the items were created at init by `M.setup_app_pill`.
				-- When the visible space has no resolvable app — e.g. a Finder desktop (no
				-- window) on a display that just lost focus, where the global front app no
				-- longer identifies this display's space — keep the pill's last app rather than
				-- blanking it, so it never vanishes out from under the active space.
				if display_title ~= "" then
					update_app_title(display_title)
				end

				M.RENDERED = indices

				-- Forget MRU/active state for spaces no longer on this display.
				local live = {}
				for _, idx in ipairs(indices) do
					live[idx] = true
				end
				for idx in pairs(M.MRU) do
					if not live[idx] then
						M.MRU[idx] = nil
					end
				end
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
		return
	end
	M.pending = true
	sbar.delay(DEBOUNCE, function()
		M.pending = false
		M.render()
	end)
end

--- Repaint every live space box from the refreshed palette using the cached active
--- flags (no yabai query). The caller refreshes the palette first.
--- @return nil
function M.theme_change_handler()
	for _, idx in ipairs(M.RENDERED) do
		local active = M.ACTIVE[idx] == true
		local space_colors = colorschemes.get_space_color_options(active, M.PIN_DARK_CHROME)
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
		local app_colors = colorschemes.get_space_color_options(true, M.PIN_DARK_CHROME)
		sbar.set(item.SPACES.APP_ICON, { icon = app_colors.icon })
		sbar.set(item.SPACES.APP_TITLE, { label = app_colors.label })
		sbar.set(item.SPACES.APP_BRACKET, { background = app_colors.background })
	end
end

return M
