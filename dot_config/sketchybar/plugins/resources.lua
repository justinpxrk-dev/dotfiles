local sbar = require("sketchybar")

local item = require("constants.item")
local option = require("constants.option")
local utils = require("helpers.utils")

-- Resource widgets mirror exelban/Stats menu-bar items into the top bar's right
-- region via sketchybar `alias` items — each renders Stats' own live graph (and,
-- for RAM, Stats' built-in `_state` status icon), prefixed by an SF Symbol
-- glyph. Requires Screen Recording permission for sketchybar and a running Stats
-- with the matching modules enabled; alias names are OS-version-specific (see
-- constants/item.lua and docs/ops/upgrade-hazards.md).
--
-- Each element is { kind, name, options, pad }. `pad` is the element's left padding (px),
-- measured so the *visible* gap to the previous element is ~20px at a section boundary
-- (the first element of CPU/GPU/RAM/Sensors), ~10px within a section, and
-- ~5px between RAM's `_state` dot and its SF Symbol icon.
-- The values differ — and some are negative — because Stats bakes its own whitespace into
-- each captured image (especially the right-aligned `_state` dots, which already supply
-- ~20px, and the leading space in the Sensors `mini` widget) and the SF glyphs carry
-- side-bearing. Re-measure (screenshot + pixel-measure the gaps) if Stats' rendering or
-- the icons change.
local widgets = {
	-- CPU
	{ "item", item.RESOURCES.CPU_ICON, option.RESOURCES.CPU_ICON, 0 },
	{ "alias", item.RESOURCES.CPU_ALIAS, option.RESOURCES.ALIAS, -2 },
	-- GPU
	{ "item", item.RESOURCES.GPU_ICON, option.RESOURCES.GPU_ICON, 8 },
	{ "alias", item.RESOURCES.GPU_ALIAS, option.RESOURCES.ALIAS, -2 },
	-- RAM (leads with the `_state` dot)
	{ "alias", item.RESOURCES.RAM_STATE_ALIAS, option.RESOURCES.ALIAS, 0 },
	{ "item", item.RESOURCES.RAM_ICON, option.RESOURCES.RAM_ICON, -5 },
	{ "alias", item.RESOURCES.RAM_CHART_ALIAS, option.RESOURCES.ALIAS, 0 },
	-- Sensors
	{ "item", item.RESOURCES.SENSORS_ICON, option.RESOURCES.SENSORS_ICON, 10 },
	{ "alias", item.RESOURCES.SENSORS_ALIAS, option.RESOURCES.ALIAS, -6 },
}

-- The `"right"` region fills right-to-left in add order, so add the list in reverse — the
-- last item added (CPU's icon) lands left-most. `utils.merge` (first wins) returns a fresh
-- table, so the shared option tables are never mutated by the per-element padding.
for i = #widgets, 1, -1 do
	local w = widgets[i]
	local opts = w[4] ~= 0 and utils.merge({ padding_left = w[4] }, w[3]) or w[3]
	sbar.add(w[1], w[2], opts)
end
