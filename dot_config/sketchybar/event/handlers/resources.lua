local sbar = require("sketchybar")

local colorschemes = require("helpers.colorschemes")
local item = require("constants.item")
local option = require("constants.option")
local utils = require("helpers.utils")

--- Builder and theme repainter for the Stats resource widgets. `M.build` constructs the
--- mirrored Stats row (CPU/GPU/RAM/Sensors/battery framed in one Stats pill, plus the clock
--- pill) into the top bar's right region; `M.theme_change_handler` recolours its
--- sketchybar-coloured chrome on a light/dark switch. The widgets are static (mirrored Stats
--- `alias` items plus chrome), so the module holds no per-render state — only the chrome item
--- names `M.build` records for the repaint.
--- @class ResourcesManager
local M = {}

--- Pill bracket item names (`STATS_PILL`, `CLOCK_PILL`), populated by `M.build` so the theme
--- handler can repaint their surfaces. Empty until `M.build` has run.
--- @type string[]
M.PILLS = {}

--- Divider item names inside the Stats pill, populated by `M.build`. The set is dynamic (one
--- hairline between each pair of same-pill widgets), so the builder lists them. Empty until
--- `M.build` has run.
--- @type string[]
M.DIVIDERS = {}

-- Resource widgets mirror exelban/Stats menu-bar items into the top bar's right
-- region via sketchybar `alias` items — each renders Stats' own live graph (and,
-- for RAM, Stats' built-in `_state` status icon), prefixed by an SF Symbol
-- glyph. The Stats widgets — CPU, GPU, RAM, Sensors, and the battery
-- (its glyph + a "mini" percentage) — are framed together in a single Stats pill: a
-- bracket reusing the inactive space-box's surface fill + border, with a 10px gap between
-- sections but a tighter 5px gap between the items inside one widget. The macOS clock follows as
-- its own pill (CLOCK_PILL) at the right end, past the Stats pill — no SF prefix, the captured
-- time text is self-identifying — reusing that same chrome, so the clock is the bar's right-most
-- item, ~2px off the macOS screen-recording dot (see PILL_TRAIL). Requires
-- Screen Recording permission for sketchybar and a running Stats with the matching
-- modules enabled; alias names are OS-version-specific (see constants/item.lua and
-- docs/ops/upgrade-hazards.md).

--- Gap (px) between adjacent pills: the visible transparent gap between their borders, 1:1. Used
--- for the spacer between the Stats pill and the clock pill that follows it at the right end.
local PILL_GAP = 10

--- Trailing spacer (px) right of the last item (the clock, the bar's right-most pill). Two jobs:
--- it un-pins the clock from the bar's right padding (so its `ipad_r` right inset takes effect — a
--- padding on the bar-edge-pinned rightmost item is otherwise a no-op), and it sets the gap to the
--- macOS screen-recording indicator dot, which overlaps the bar's far-right corner by ~9px — so the
--- visible gap is this spacer minus ~9px, tuned so the clock sits ~2px off the dot. Re-measure if
--- the dot's position moves.
local PILL_TRAIL = 11

-- Each element is { kind, name, options, ipad_l, ipad_r } — its left/right padding (px). The
-- values differ — and several are negative — because Stats bakes its own whitespace into each
-- captured image (especially the right-aligned `_state` dots and the chart/Sensors images'
-- trailing margin) and the SF glyphs carry side-bearing, so a literal 10px padding renders as
-- anything from 0 to 19px. They were derived by pixel-measuring the rendered pills so the
-- spacing reads at two tiers: ~10px throughout (each pill's border→content insets, the gaps
-- between sections, and the gap between the two pills) but ~5px between the items *within* a
-- section (each widget's icon→graph, and RAM's `_state`→icon→chart) so a widget's own parts
-- read as one unit. Re-measure (screenshot + pixel-measure) if Stats' rendering or the icons
-- change.

local sections = {
	{
		group = item.RESOURCES.STATS_PILL,
		elements = {
			{ "item", item.RESOURCES.CPU_ICON, option.RESOURCES.CPU_ICON, 9, 0 },
			-- ipad_l trims 5px off the icon→graph gap (the within-section gap is ~5px, half the ~10px
			-- between-section gap); ipad_r trims the graph image's baked-right whitespace so the
			-- following divider's left gap centres at ~10px.
			{ "alias", item.RESOURCES.CPU_ALIAS, option.RESOURCES.ALIAS, -7, -3 },
		},
	},
	{
		group = item.RESOURCES.STATS_PILL,
		-- div_pad_l/div_pad_r: pixel-measured to centre the preceding divider ~10px on each side
		-- (asymmetric because the neighbouring elements' baked whitespace / negative ipads differ).
		div_pad_l = 1,
		div_pad_r = 16,
		elements = {
			{ "item", item.RESOURCES.GPU_ICON, option.RESOURCES.GPU_ICON, -8, 0 },
			-- ipad_l trims 5px off the icon→graph gap to the ~5px within-section spacing.
			{ "alias", item.RESOURCES.GPU_ALIAS, option.RESOURCES.ALIAS, -7, -1 },
		},
	},
	{
		group = item.RESOURCES.STATS_PILL,
		-- Leads with the `_state` dot. div_pad_l/div_pad_r: pixel-measured to centre the preceding
		-- divider ~10px on each side.
		div_pad_l = 0,
		div_pad_r = 17,
		elements = {
			{ "alias", item.RESOURCES.RAM_STATE_ALIAS, option.RESOURCES.ALIAS, -16, 0 },
			-- RAM_ICON.ipad_l makes the _state→icon a deliberate tight ~2px (the status dot hugging the
			-- icon); RAM_CHART_ALIAS.ipad_l trims 5px off the icon→chart gap to the ~5px tier. RAM_CHART_ALIAS.ipad_r
			-- trims the chart image's wide baked-right whitespace (~12px) so the following divider's
			-- left gap is set by Sensors' `div_pad_l` rather than pushed out by that whitespace.
			{ "item", item.RESOURCES.RAM_ICON, option.RESOURCES.RAM_ICON, -8, 0 },
			{ "alias", item.RESOURCES.RAM_CHART_ALIAS, option.RESOURCES.ALIAS, -5, -12 },
		},
	},
	{
		group = item.RESOURCES.STATS_PILL,
		-- div_pad_l/div_pad_r: pixel-measured to centre the preceding divider ~10px on each side
		-- (the left side also relies on RAM_CHART_ALIAS.ipad_r trimming the chart's baked whitespace).
		div_pad_l = 13,
		div_pad_r = 22,
		elements = {
			{ "item", item.RESOURCES.SENSORS_ICON, option.RESOURCES.SENSORS_ICON, -13, 0 },
			-- ipad_l trims 5px off the icon→graph gap to the ~5px within-section spacing. ipad_r is
			-- sharply negative because the temp-only Sensors image bakes wide trailing whitespace
			-- (Stats sizes the value field for more than "NN°"); trimming it lands the between-section
			-- gap to the battery glyph at ~10px.
			{ "alias", item.RESOURCES.SENSORS_ALIAS, option.RESOURCES.ALIAS, -9, -25 },
		},
	},
	-- Stats battery (oneView off → two menu-bar items): the battery glyph then its "mini"
	-- percentage, a tight pair (~5px within-section gap, set by the percentage's ipad_l). Both
	-- join the Stats pill as its right-most widgets, so the percentage's `ipad_r` sets that pill's
	-- right border inset. Pixel-measured like the rest.
	{
		group = item.RESOURCES.STATS_PILL,
		-- div_pad_l/div_pad_r: pixel-measured to centre the preceding divider ~10px on each side.
		div_pad_l = 18,
		div_pad_r = 2,
		elements = {
			{ "alias", item.RESOURCES.BATTERY_ALIAS, option.RESOURCES.ALIAS, -2, 0 },
			{ "alias", item.RESOURCES.BATTERY_PCT_ALIAS, option.RESOURCES.ALIAS, -18, -3 },
		},
	},
	-- The macOS clock is its own pill at the right end (CLOCK_PILL), past the Stats pill — a
	-- different group, so the build loop separates them with a plain transparent spacer (no
	-- divider), the pills' own borders doing the separating. `gap = 10` holds that 10px from the
	-- Stats pill. The clock image bakes wide side whitespace: `ipad_l = 0` lets the baked-left
	-- whitespace stand in as the pill's ~10px left inset, while `ipad_r` trims the baked-right
	-- whitespace to the matching inset. The trailing spacer holds it ~2px off the recording dot
	-- (see PILL_TRAIL).
	{
		group = item.RESOURCES.CLOCK_PILL,
		gap = 10,
		elements = {
			{ "alias", item.RESOURCES.CLOCK_ALIAS, option.RESOURCES.ALIAS, 0, -11 },
		},
	},
}

--- Bracket options for one resource pill: a neutral container reusing the inactive space
--- box's surface fill + border (tracking the live theme) and the same box geometry, so the stats
--- pills read as siblings of the space pills. Repainted on a light/dark switch by the Stats theme
--- handler (see `M.theme_change_handler`).
--- @return table options sketchybar `bracket` background + geometry
local function pill_options()
	local colors = colorschemes.get_space_color_options(false)
	return utils.merge(option.SPACES.BRACKET, { background = colors.background })
end

--- Transparent spacer options of a given width (the inter-pill gaps and the trailing spacer).
--- @param width integer item width in px
--- @return table options
local function spacer_options(width)
	return utils.merge({ width = width }, option.SPACES.SPACER)
end

--- Vertical hairline that separates two widgets inside one pill. Same construction as a space
--- box's number│glyphs divider (`option.SPACES.DIVIDER`): a 2px line that carries no padding of
--- its own, so — exactly like there — the gap on each side comes from a standalone spacer (sized
--- in the build loop) and the line sits with clear space on both. Filled with the bright *active*
--- foreground (the colour an active space's glyphs take) so the lines read as lit/active rather
--- than a dim hairline. Tracks the live theme — repainted on a light/dark switch by the Stats
--- theme handler (see `M.theme_change_handler`).
--- @return table options
local function divider_options()
	local colors = colorschemes.get_space_color_options(true)
	return utils.merge({ background = { color = colors.icon.color } }, option.SPACES.DIVIDER)
end

--- Build the left-to-right add sequence (each section's elements, an inter-section separator
--- before every section but the first, and a trailing spacer past the last) plus the per-group
--- bracket member lists; then add the items in reverse — the `"right"` region fills right-to-left,
--- so the last added (CPU's icon) lands left-most — and the group brackets last (members must
--- already exist). `utils.merge` (first wins) returns a fresh table, so the shared option tables
--- are never mutated by the per-element padding.
--- @return nil
function M.build()
	local seq = {}
	local groups = {} -- group name -> ordered list of member item names
	local group_order = {} -- group names in first-seen (left-to-right) order
	local dividers = {} -- divider item names, recorded so the theme handler can repaint them
	for si, section in ipairs(sections) do
		if si > 1 then
			local gap = section.gap or PILL_GAP
			if section.group == sections[si - 1].group then
				-- Two widgets of the same pill: a hairline divider with a full `gap` spacer on each
				-- side (a space box's number│divider│glyph spacing). The divider is a bracket member;
				-- the two spacers are not, so they read as the gaps framed by the pill's fill. In a
				-- right-anchored region the left spacer alone sets the gap to the previous widget and
				-- the right spacer alone the gap to the next, so the two tune independently. Each
				-- gap takes a per-widget override (`div_pad_l`/`div_pad_r`) because the neighbouring elements
				-- carry large negative `ipad`s (trimming their images' baked whitespace) that shift them
				-- over the spacer — pixel-tuned so both gaps land at ~10px and the line sits centred.
				seq[#seq + 1] =
					{ "item", item.RESOURCES.PILL_SPACER .. si .. "l", spacer_options(section.div_pad_l or gap) }
				seq[#seq + 1] = { "item", item.RESOURCES.PILL_DIVIDER .. si, divider_options(), section.group }
				dividers[#dividers + 1] = item.RESOURCES.PILL_DIVIDER .. si
				seq[#seq + 1] =
					{ "item", item.RESOURCES.PILL_SPACER .. si .. "r", spacer_options(section.div_pad_r or gap) }
			else
				-- Two different pills (Stats → clock): a plain transparent spacer — the pills' own
				-- borders already separate them, so no divider.
				seq[#seq + 1] = { "item", item.RESOURCES.PILL_SPACER .. si, spacer_options(gap) }
			end
		end
		for _, el in ipairs(section.elements) do
			seq[#seq + 1] =
				{ el[1], el[2], utils.merge({ padding_left = el[4], padding_right = el[5] }, el[3]), section.group }
		end
	end
	-- Accumulate every seq entry that names a group (the section elements and the same-pill dividers,
	-- carried in `entry[4]`) into that group's bracket member list, in left-to-right order. The
	-- spacers carry no group, so they stay non-members (gaps framed by the fill, not framed items).
	for _, entry in ipairs(seq) do
		local group = entry[4]
		if group then
			if not groups[group] then
				groups[group] = {}
				group_order[#group_order + 1] = group
			end
			local g = groups[group]
			g[#g + 1] = entry[2]
		end
	end
	-- Trailing spacer right of the last item (rightmost): un-pins the clock — the bar's right-most
	-- pill — and clears the recording dot (see PILL_TRAIL). Not a bracket member, so it only pushes
	-- the row left.
	seq[#seq + 1] = { "item", item.RESOURCES.PILL_SPACER .. "trail", spacer_options(PILL_TRAIL) }

	-- Every stats item lives in the `"right"` region; the per-element options carry that, but the
	-- spacers and dividers (from option.SPACES.SPACER/DIVIDER) do not, so set it here or they would
	-- land in the default region and collapse the inter-pill gaps to nothing.
	for i = #seq, 1, -1 do
		local s = seq[i]
		sbar.add(s[1], s[2], utils.merge({ position = "right" }, s[3]))
	end
	-- One bracket per group, framing its members as a single unit (STATS_PILL, then CLOCK_PILL at the
	-- right end). The Stats pill's inter-widget dividers sit inside its span, framed by the same fill.
	for _, gname in ipairs(group_order) do
		sbar.add("bracket", gname, groups[gname], pill_options())
	end

	-- Record the pill brackets and dividers so the Stats theme handler repaints exactly the chrome
	-- that exists (the divider set is dynamic — one between each pair of same-pill widgets).
	M.PILLS = group_order
	M.DIVIDERS = dividers
end

--- Repaint the Stats/clock chrome from the refreshed palette so it tracks light/dark in step with
--- the space pills: the leading SF Symbol icons take the live foreground, each pill bracket
--- re-takes the inactive space-box surface (fill + border), and each divider re-takes the bright
--- active foreground. The Stats `alias` items are coloured by Stats itself, so they are left
--- untouched. The caller refreshes the palette first.
--- @return nil
function M.theme_change_handler()
	local icon_colors = colorschemes.get_default_color_options()
	sbar.set(item.RESOURCES.CPU_ICON, icon_colors)
	sbar.set(item.RESOURCES.GPU_ICON, icon_colors)
	sbar.set(item.RESOURCES.RAM_ICON, icon_colors)
	sbar.set(item.RESOURCES.SENSORS_ICON, icon_colors)

	local pill_background = colorschemes.get_space_color_options(false).background
	for _, pill in ipairs(M.PILLS) do
		sbar.set(pill, { background = pill_background })
	end

	local divider_color = colorschemes.get_space_color_options(true).icon.color
	for _, divider in ipairs(M.DIVIDERS) do
		sbar.set(divider, { background = { color = divider_color } })
	end
end

return M
