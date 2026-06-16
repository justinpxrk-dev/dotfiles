local sbar = require("sketchybar")

local colorschemes = require("helpers.colorschemes")
local item = require("constants.item")
local option = require("constants.option")
local utils = require("helpers.utils")

-- Resource widgets mirror exelban/Stats menu-bar items into the top bar's right
-- region via sketchybar `alias` items — each renders Stats' own live graph (and,
-- for RAM, Stats' built-in `_state` status icon), prefixed by an SF Symbol
-- glyph. Requires Screen Recording permission for sketchybar and a running Stats
-- with the matching modules enabled; alias names are OS-version-specific (see
-- constants/item.lua and docs/ops/upgrade-hazards.md). The four widgets (CPU, GPU,
-- RAM, Sensors) are framed together as a single Stats pill — one
-- bracket reusing the inactive space-box's surface fill + border — with a uniform
-- 10px gap between the widgets inside it.

--- Gap (px) between adjacent sections — the visible gap between the widgets inside the Stats
--- pill. Each element's negative ipad trims its image's baked whitespace, so the spacer width
--- renders as the visible glyph-to-glyph gap.
local PILL_GAP = 10

--- Trailing spacer (px) right of the last item (Sensors, the right-most). Two jobs: it un-pins
--- Sensors from the bar's right padding (so its `ipad_r` right inset takes effect — a padding on
--- the bar-edge-pinned rightmost item is otherwise a no-op), and it sets the ~10px gap from the
--- macOS screen-recording indicator dot, which sits at a fixed point overlapping the bar's
--- far-right corner. Re-measure if the dot's position changes.
local PILL_TRAIL = 16

-- Each element is { kind, name, options, ipad_l, ipad_r } — its left/right padding (px). The
-- values differ — and several are negative — because Stats bakes its own whitespace into each
-- captured image (especially the right-aligned `_state` dots and the chart/Sensors images'
-- trailing margin) and the SF glyphs carry side-bearing, so a literal 10px padding renders as
-- anything from 0 to 19px. They were derived by pixel-measuring the rendered pill so the unit's
-- border insets are ~10px, the gaps between widgets ~10px, and a `_state` dot→icon gap ~5px.
-- Re-measure (screenshot + pixel-measure) if Stats' rendering or the icons change.
local sections = {
	{
		group = item.RESOURCES.STATS_PILL,
		elements = {
			{ "item", item.RESOURCES.CPU_ICON, option.RESOURCES.CPU_ICON, 9, 0 },
			{ "alias", item.RESOURCES.CPU_ALIAS, option.RESOURCES.ALIAS, -2, -1 },
		},
	},
	{
		group = item.RESOURCES.STATS_PILL,
		elements = {
			{ "item", item.RESOURCES.GPU_ICON, option.RESOURCES.GPU_ICON, -8, 0 },
			{ "alias", item.RESOURCES.GPU_ALIAS, option.RESOURCES.ALIAS, -2, -1 },
		},
	},
	{
		group = item.RESOURCES.STATS_PILL,
		-- Leads with the `_state` dot.
		elements = {
			{ "alias", item.RESOURCES.RAM_STATE_ALIAS, option.RESOURCES.ALIAS, -16, 0 },
			{ "item", item.RESOURCES.RAM_ICON, option.RESOURCES.RAM_ICON, -5, 0 },
			{ "alias", item.RESOURCES.RAM_CHART_ALIAS, option.RESOURCES.ALIAS, 0, 1 },
		},
	},
	{
		group = item.RESOURCES.STATS_PILL,
		elements = {
			{ "item", item.RESOURCES.SENSORS_ICON, option.RESOURCES.SENSORS_ICON, -9, 0 },
			-- ipad_r is negative because the Sensors image bakes ~18px of trailing whitespace; it
			-- sets the unit's ~10px right inset. Sensors is the right-most item, so the trailing
			-- spacer un-pins it for this inset to take effect.
			{ "alias", item.RESOURCES.SENSORS_ALIAS, option.RESOURCES.ALIAS, -4, -8 },
		},
	},
}

--- Bracket options for the Stats pill: a neutral container reusing the inactive space box's
--- surface fill + border on the always-dark palette (the top bar is pinned black), and the same
--- box geometry, so the Stats pill reads as a sibling of the space pills.
--- @return table options sketchybar `bracket` background + geometry
local function pill_options()
	local colors = colorschemes.get_space_color_options(false, true)
	return utils.merge(option.SPACES.BRACKET, { background = colors.background })
end

--- Transparent spacer options of a given width (the inter-widget gaps and the trailing spacer).
--- @param width integer item width in px
--- @return table options
local function spacer_options(width)
	return utils.merge({ width = width }, option.SPACES.SPACER)
end

-- Build the left-to-right add sequence (each section's elements, an inter-section spacer before
-- every section but the first, and a trailing spacer past the last) plus the per-group bracket
-- member lists; then add the items in reverse — the `"right"` region fills right-to-left, so
-- the last added (CPU's icon) lands left-most — and the group brackets last (members must
-- already exist). `utils.merge` (first wins) returns a fresh table, so the shared option tables
-- are never mutated by the per-element padding.
local seq = {}
local groups = {} -- group name -> ordered list of member item names
local group_order = {} -- group names in first-seen (left-to-right) order
for si, section in ipairs(sections) do
	if si > 1 then
		seq[#seq + 1] = { "item", item.RESOURCES.PILL_SPACER .. si, spacer_options(section.gap or PILL_GAP) }
	end
	for _, el in ipairs(section.elements) do
		seq[#seq + 1] = { el[1], el[2], utils.merge({ padding_left = el[4], padding_right = el[5] }, el[3]) }
		-- Accumulate this element into its group's bracket member list (each group is one unit).
		if section.group then
			if not groups[section.group] then
				groups[section.group] = {}
				group_order[#group_order + 1] = section.group
			end
			local g = groups[section.group]
			g[#g + 1] = el[2]
		end
	end
end
-- Trailing spacer right of the last item (Sensors, the right-most): un-pins it and clears the
-- recording dot (see PILL_TRAIL). Not a bracket member, so it only pushes the row left.
seq[#seq + 1] = { "item", item.RESOURCES.PILL_SPACER .. "trail", spacer_options(PILL_TRAIL) }

-- Every stats item lives in the `"right"` region; the per-element options carry that, but the
-- spacers (from option.SPACES.SPACER) do not, so set it here or they would land in the default
-- region and collapse the inter-widget gaps to nothing.
for i = #seq, 1, -1 do
	local s = seq[i]
	sbar.add(s[1], s[2], utils.merge({ position = "right" }, s[3]))
end
-- One bracket per group framing its members as a single unit (here just STATS_PILL). A group's
-- inter-widget spacers sit inside its span, framed by the same fill.
for _, gname in ipairs(group_order) do
	sbar.add("bracket", gname, groups[gname], pill_options())
end
