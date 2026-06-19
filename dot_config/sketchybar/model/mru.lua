--- Per-space most-recently-used (MRU) app ordering — the sketchybar config's one piece of pure
--- domain state, and the first occupant of the `model/` boundary.
---
--- A module belongs in `model/` iff it satisfies this contract:
---   * no `require("sketchybar")` — zero dependency on the bar/runtime,
---   * no presentation concerns — it deals in app-name strings only, never glyphs or item names,
---   * unit-testable as plain Lua.
--- This is the config's only sketchybar-free, testable zone. The space renderer
--- (event/handlers/spaces.lua) drives this model; its view-mirror state (RENDERED / ACTIVE /
--- GLYPH_COUNT) deliberately stays with the renderer because that IS presentation, not model.
---
--- State is process-local: SbarLua keeps each sketchybar process's Lua state alive across the event
--- loop, and each process renders only its own display's spaces, so `store` only ever holds this
--- display's spaces (keyed by yabai space index).
--- @class Mru
local M = {}

--- Per-space app order, most-recent first, deduped by app name. Private to the module — callers
--- reach it only through the functions below, which keeps the boundary honest.
--- @type table<integer, string[]>
local store = {}

--- Move `app` to the front of space `index`'s MRU list (the app you're now using).
--- @param index integer space index
--- @param app string app name
--- @return nil
function M.promote(index, app)
	local next_list = { app }
	for _, a in ipairs(store[index] or {}) do
		if a ~= app then
			next_list[#next_list + 1] = a
		end
	end
	store[index] = next_list
end

--- Reconcile a space's MRU against the apps currently present in it: keep present apps in their
--- existing recency order, then append newly-present apps (first-seen order) at the back. Apps that
--- have closed drop out. Updates the stored order as a side effect, so it runs once per space.
--- @param index integer space index
--- @param present string[] apps currently in the space, first-seen order
--- @return string[] reconciled MRU, most-recent first
function M.reconcile(index, present)
	local present_set = {}
	for _, app in ipairs(present) do
		present_set[app] = true
	end

	local kept, kept_set = {}, {}
	for _, app in ipairs(store[index] or {}) do
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

	store[index] = kept
	return kept
end

--- Forget MRU state for spaces no longer on this display.
--- @param live table<integer, boolean> set of space indices still present
--- @return nil
function M.prune(live)
	for idx in pairs(store) do
		if not live[idx] then
			store[idx] = nil
		end
	end
end

--- Drop all stored MRU state. Test-only — production prunes selectively (see `M.prune`); this exists
--- so a test process can reset between cases, honouring the module's "unit-testable" contract.
--- @return nil
function M.reset()
	store = {}
end

return M
