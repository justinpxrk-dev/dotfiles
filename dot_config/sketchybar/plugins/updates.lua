local sbar = require("sketchybar")

local colorschemes = require("helpers.colorschemes")
local icon = require("constants.icon")
local item = require("constants.item")
local option = require("constants.option")
local updates = require("event.handlers.updates")
local utils = require("helpers.utils")

-- Updates pill: one segment per "provider" (a tool with an outdated-count script), framed as a
-- single surface pill in the top bar's right region, just left of the Stats pill — hidden entirely
-- until at least one provider reports updates. Each segment is a Nerd Font glyph + that provider's
-- count, separated by hairline dividers (shown only between two visible segments). This plugin
-- builds the items and registers the providers; `event/handlers/updates.lua` owns the polling and
-- the show/hide logic. Top bar only, like the Stats and now-playing pills.

--- Gap (px) between the updates pill and the Stats pill on its right — the same 10px inter-pill gap
--- the Stats and clock pills use. A standalone item (not a bracket member) so the pill's own border
--- insets stay separate; hidden with the pill so no phantom gap remains when there are no updates.
local PILL_GAP = 10

--- Default poll cadence (seconds) for a provider that does not set its own. 3600 (hourly): outdated
--- counts move slowly, and Homebrew only actually re-fetches on its own ~daily auto-update anyway
--- (see event/providers/brew.sh). sketchybar fires one `routine` at startup regardless of the
--- cadence, so each segment populates on load and then refreshes on this interval.
local DEFAULT_FREQ = 3600

--- Provider registry — the modular contract. Each entry becomes one segment, left→right in the
--- order listed: a Nerd Font `glyph`, the `name` that keys both its count script
--- (`event/providers/<name>.sh`) and its `M.counts` entry, and a poll `freq`. Adding a source
--- (macOS updates, chezmoi drift, …) is one entry here plus that script — nothing in the handler's
--- visibility/divider logic is provider-specific.
local providers = {
	{ name = "brew", glyph = icon.UPDATES.BREW, freq = DEFAULT_FREQ },
	{ name = "mise", glyph = icon.UPDATES.MISE, freq = DEFAULT_FREQ },
}

--- Directory of the applied count scripts (chezmoi strips the `executable_` prefix on apply).
local PROVIDERS_DIR = os.getenv("HOME") .. "/.config/sketchybar/event/providers/"

-- Pill chrome. Unlike the surface-filled Stats/space pills, the updates pill is a mauve "system"
-- pill — the accent + knockout styling of the Apple badge and active-app title pill — so it stands
-- out when it appears: the bracket is a solid mauve box (the active-space border colour reused as
-- the fill, exactly like `apple_bracket_options` in spaces.lua), and the glyph, count, and hairline
-- take the bar's own background colour, reading as cutouts in the mauve. Geometry still comes from
-- the shared space-box options. Colors come from the live palette up front and are repainted on a
-- light/dark switch by the handler. `utils.merge` (first wins) returns a fresh table, so the shared
-- option tables are never mutated.
local mauve = colorschemes.get_space_color_options(true).background.border_color
local knockout = colorschemes.get_bar_background()

--- Segment options for a provider: its glyph layered onto the shared SEGMENT styling, plus the
--- `update_freq` that drives this segment's own poll. Starts hidden (from SEGMENT).
--- @param glyph string the provider's Nerd Font glyph
--- @param freq integer poll cadence in seconds
--- @return table
local function segment_options(glyph, freq)
	return utils.merge({ icon = { string = glyph }, update_freq = freq }, option.UPDATES.SEGMENT)
end

--- Hairline divider between two segments: the space-box divider line forced into the right region,
--- in the knockout colour (the bar's background) so it reads as a cutout in the mauve fill like the
--- glyphs, and hidden until the handler shows it between two visible segments.
--- @return table
local function divider_options()
	return utils.merge(
		{ position = "right", drawing = false, background = { color = knockout } },
		option.SPACES.DIVIDER
	)
end

--- Trailing inter-pill spacer (the gap to the Stats pill): a transparent `PILL_GAP`-wide item in
--- the right region, hidden until the pill is shown.
--- @return table
local function spacer_options()
	return utils.merge({ width = PILL_GAP, position = "right", drawing = false }, option.SPACES.SPACER)
end

--- Pill bracket: a solid mauve box (fill + border) framing the segments + dividers — the system-pill
--- accent of the Apple badge / app-title pill — hidden until the pill is shown.
--- @return table
local function bracket_options()
	return utils.merge({ drawing = false, background = { color = mauve, border_color = mauve } }, option.SPACES.BRACKET)
end

-- Build the add sequence in visual left→right order — seg1, div1, seg2, …, segN, trailing spacer —
-- recording each provider descriptor for the handler and collecting the bracket's members (the
-- segments and the dividers; NOT the trailing spacer, which frames the gap *outside* the pill).
local seq = {} -- { kind, name, options } left→right
local members = {} -- bracket member names, left→right
for i, p in ipairs(providers) do
	local segment = item.UPDATES.PREFIX .. p.name
	seq[#seq + 1] = { "item", segment, segment_options(p.glyph, p.freq) }
	members[#members + 1] = segment
	updates.PROVIDERS[i] = {
		name = p.name,
		segment = segment,
		command = PROVIDERS_DIR .. p.name .. ".sh",
		freq = p.freq,
		-- Per-provider on-demand refresh event, fired by the zsh hook in
		-- dot_config/zsh/dot_zshrc_hooks after a matching `brew`/`mise` upgrade. The name pattern is
		-- the contract between that hook and this plugin — keep them in sync (see
		-- docs/ops/upgrade-hazards.md).
		event = "updates_" .. p.name .. "_refresh",
	}
	if i < #providers then
		local divider = item.UPDATES.PREFIX .. p.name .. ".div"
		seq[#seq + 1] = { "item", divider, divider_options() }
		members[#members + 1] = divider
		updates.DIVIDERS[i] = divider
	end
end
seq[#seq + 1] = { "item", item.UPDATES.SPACER, spacer_options() }

-- The `"right"` region fills right-to-left in add order, and this plugin is required after
-- `plugins.resources`, so add in REVERSE: the trailing spacer goes first → right-most, landing just
-- left of the Stats pill (the inter-pill gap); provider 1's segment goes last → left-most. Capture
-- the item handles so the segments can subscribe to their poll below.
local handles = {}
for i = #seq, 1, -1 do
	local s = seq[i]
	handles[s[2]] = sbar.add(s[1], s[2], s[3])
end

-- Frame the segments + dividers as one pill (members must already exist). Record the chrome the
-- handler toggles/repaints.
sbar.add("bracket", item.UPDATES.PILL, members, bracket_options())
updates.BRACKET = item.UPDATES.PILL
updates.SPACER = item.UPDATES.SPACER

-- Drive each segment's count three ways: (1) a `routine` subscription fires every `update_freq`
-- seconds — the periodic backstop, covering upgrades run outside an interactive shell; (2) the
-- per-provider custom event (`updates_<name>_refresh`) for instant on-demand updates — the zsh
-- `brew`/`mise` wrappers (dot_config/zsh/dot_zshrc_aliases) fire it right after a successful upgrade,
-- carrying the freshly-computed count as `COUNT=…` so the pill applies it directly instead of
-- re-polling (and `set_count` redraws only if it changed); (3) an explicit poll right now populates
-- the pill on load, since sketchybar does NOT fire an initial `routine` at startup. A hidden segment
-- keeps receiving the event (independent of `drawing`), so a provider that dropped to 0 reappears
-- when its source has updates again.
for _, p in ipairs(updates.PROVIDERS) do
	sbar.add("event", p.event)
	handles[p.segment]:subscribe({ "routine", p.event }, function(env)
		local pushed = env and env.COUNT and tonumber(env.COUNT)
		if pushed then
			updates.set_count(p, pushed)
		else
			updates.refresh(p)
		end
	end)
	updates.refresh(p)
end
