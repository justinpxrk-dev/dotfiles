local sbar = require("sketchybar")

local colorschemes = require("helpers.colorschemes")

--- Updates pill: one segment per "provider" (a tool with an outdated-count script — brew, mise,
--- …), aggregated into a single pill that is hidden until at least one provider reports updates.
--- This module owns the runtime state and behaviour; `plugins/updates.lua` builds the items and
--- registers the providers. Module-level state persists across triggers because the SbarLua event
--- loop keeps the Lua process alive (one instance, on the top bar only).
---
--- The contract is provider-count-agnostic: providers push their counts in via `M.refresh`, and
--- `M.recompute` derives all visibility/layout from `M.counts` alone — so adding a provider needs
--- no change here.
--- @class UpdatesManager
local M = {}

--- Inner margin (px) from a segment's glyph/count to the pill's bracket border — the first visible
--- segment's left inset and the last visible segment's right inset. 10px to match the space boxes
--- and the Stats pill.
local INNER = 10

--- Gap (px) between a segment and an adjacent hairline divider (one on each side of the line, like
--- the space box's number│glyph spacing). 10px, matching `INNER`.
local GAP = 10

--- Ordered provider descriptors, recorded by `plugins/updates.lua` left→right. Each is
--- `{ name, segment, command, freq, event }`: the provider key, its sketchybar segment item, the
--- count-script path, its poll cadence, and its on-demand refresh event name. Empty until the
--- plugin runs.
--- @type { name: string, segment: string, command: string, freq: integer, event: string }[]
M.PROVIDERS = {}

--- Hairline divider item names, ordered so `DIVIDERS[i]` is the line physically between provider
--- `i` and provider `i+1` (so there are `#PROVIDERS - 1` of them). Recorded by the plugin.
--- @type string[]
M.DIVIDERS = {}

--- The pill's framing bracket item, recorded by the plugin.
--- @type string?
M.BRACKET = nil

--- The trailing inter-pill spacer (the gap from the pill to the Stats pill on its right),
--- recorded by the plugin. Hidden with the pill so no phantom gap remains when there are no
--- updates.
--- @type string?
M.SPACER = nil

--- Latest outdated count per provider name. `nil` until a provider's first poll completes; a `nil`
--- count is treated as 0 (segment hidden), so the pill starts collapsed and only appears once a
--- poll finds updates.
--- @type table<string, integer>
M.counts = {}

--- Recompute the pill's visibility and layout from `M.counts` alone:
--- - a segment is shown only when its own count is > 0 (so one provider can show while another is
---   hidden), taking the pill's inner margin on the side that meets the bracket border and the
---   inter-divider gap on a side that faces another segment;
--- - the whole pill — bracket plus its trailing inter-pill spacer — is shown only when some count
---   is > 0;
--- - a hairline is drawn only *between two currently-visible segments*. The rule "draw the divider
---   after segment `i` iff segment `i` is visible AND some later segment is visible" yields exactly
---   (visible − 1) dividers and stays correct even if a middle segment hides: the surviving line is
---   the one physically right after the last-visible segment that still has a visible successor, and
---   the hidden segments/dividers between them collapse to nothing.
---
--- Item visibility is toggled via each item's own `drawing` flag (never `background.drawing`):
--- setting `background.color` — which `theme_change_handler` does — implicitly re-enables
--- `background.drawing`, so a hairline/bracket gated on `background.drawing` would pop back on after
--- a recolor. A hidden segment is also zeroed on padding so it collapses fully (a still-drawn empty
--- item would hold the bracket open). `position` is never re-set here: re-setting it re-inserts the
--- item at the end of its region and would reshuffle the pill.
--- @return nil
function M.recompute()
	local provs = M.PROVIDERS
	local visible, first_visible, last_visible = {}, nil, nil
	for i, p in ipairs(provs) do
		visible[i] = (M.counts[p.name] or 0) > 0
		if visible[i] then
			first_visible = first_visible or i
			last_visible = i
		end
	end

	local any = first_visible ~= nil
	sbar.set(M.BRACKET, { drawing = any })
	sbar.set(M.SPACER, { drawing = any })

	for i, p in ipairs(provs) do
		if visible[i] then
			sbar.set(p.segment, {
				drawing = true,
				padding_left = (i == first_visible) and INNER or GAP,
				padding_right = (i == last_visible) and INNER or GAP,
				label = { string = tostring(M.counts[p.name]) },
			})
		else
			sbar.set(p.segment, { drawing = false, padding_left = 0, padding_right = 0 })
		end
	end

	for i = 1, #provs - 1 do
		local later_visible = false
		for j = i + 1, #provs do
			if visible[j] then
				later_visible = true
				break
			end
		end
		sbar.set(M.DIVIDERS[i], { drawing = visible[i] and later_visible })
	end
end

--- Record a provider's outdated count and recompute the pill — but only when the value actually
--- changed, so a poll (or a pushed count) that matches what's already shown does no redraw.
--- @param provider { name: string }
--- @param count integer
--- @return nil
function M.set_count(provider, count)
	if M.counts[provider.name] ~= count then
		M.counts[provider.name] = count
		M.recompute()
	end
end

--- Poll one provider's count script asynchronously and fold the result into `M.counts`, then
--- recompute (via `set_count`). `sbar.exec` forks the command, so a slow `brew`/`mise` never stalls
--- the bar; the callback receives the script's stdout. A non-numeric or empty result (a script
--- error) is taken as 0, so a transient failure reads as "no updates" rather than a stuck count.
--- Used for the periodic poll and the startup poll; an interactive upgrade instead *pushes* its
--- count straight to `set_count` (see plugins/updates.lua), skipping this re-poll.
--- @param provider { name: string, command: string } the provider to poll
--- @return nil
function M.refresh(provider)
	sbar.exec(provider.command, function(out)
		M.set_count(provider, tonumber(out) or 0)
	end)
end

--- Repaint the pill chrome from the live palette (called on a light/dark switch and once at
--- startup), keeping the system-pill look of the Apple badge / app-title pill: the bracket re-takes
--- the mauve accent (the active-space border colour used as a solid fill), and each segment's glyph
--- + count and each hairline re-take the knockout colour (the bar's own background), so they read as
--- cutouts in the mauve. Visibility is left untouched — item-level `drawing` survives the
--- `background.color` re-enable (see `M.recompute`) — so hidden chrome stays hidden. The caller
--- refreshes the palette first.
--- @return nil
function M.theme_change_handler()
	local knockout = { color = colorschemes.get_bar_background() }
	for _, p in ipairs(M.PROVIDERS) do
		sbar.set(p.segment, { icon = knockout, label = knockout })
	end

	local mauve = colorschemes.get_space_color_options(true).background.border_color
	sbar.set(M.BRACKET, { background = { color = mauve, border_color = mauve } })

	for _, divider in ipairs(M.DIVIDERS) do
		sbar.set(divider, { background = knockout })
	end
end

return M
