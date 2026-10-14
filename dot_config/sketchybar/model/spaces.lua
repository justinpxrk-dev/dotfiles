--- Build one display's space state from yabai snapshots and retain its app history.
local M = {}

--- @class SpaceState
--- @field id integer Stable yabai space ID, independent of its displayed index.
--- @field index integer Current Mission Control number.
--- @field active boolean Whether the space is visible on its display.
--- @field apps string[] Most recently focused first, with one entry per app.

--- @class SpacesSnapshot
--- @field displays table[]
--- @field spaces table[]
--- @field windows table[]
--- @field front_app string? Front app name; empty or absent when unavailable.

--- @class SpacesState
--- @field display integer? Current arrangement index, nil when disconnected.
--- @field spaces SpaceState[] Ordered by their current Mission Control numbers.
--- @field app string App title for this display's visible space, empty when unknown.

--- @class SpacesModel
--- @field update fun(snapshot: SpacesSnapshot): SpacesState

--- Retain present apps in recency order, promoting the focused app and appending newcomers.
--- @param previous string[]
--- @param present string[]
--- @param focused string?
--- @return string[]
local function order_apps(previous, present, focused)
	local available, used, ordered = {}, {}, {}
	for _, app in ipairs(present) do
		available[app] = true
	end

	--- Append an app once, provided it still has a window in this space.
	--- @param app string?
	--- @return nil
	local function append(app)
		if app and available[app] and not used[app] then
			ordered[#ordered + 1] = app
			used[app] = true
		end
	end

	append(focused)
	for _, app in ipairs(previous) do
		append(app)
	end
	for _, app in ipairs(present) do
		append(app)
	end
	return ordered
end

--- Compare space numbers so renumbered spaces keep their current display order.
--- @param first SpaceState
--- @param second SpaceState
--- @return boolean
local function by_index(first, second)
	return first.index < second.index
end

--- Create a model bound to one physical display, with independent recency and title caches.
--- @param display_uuid string Stable yabai display UUID.
--- @return SpacesModel
function M.new(display_uuid)
	local recent, titles = {}, {}
	local model = {}

	--- Resolve the display and derive its space state, pruning history for departed spaces.
	--- @param snapshot SpacesSnapshot
	--- @return SpacesState
	function model.update(snapshot)
		local display
		for _, candidate in ipairs(snapshot.displays) do
			if candidate.uuid == display_uuid then
				display = candidate.index
				break
			end
		end

		local windows = {}
		for _, window in ipairs(snapshot.windows) do
			windows[window.id] = window
		end

		--- @type SpaceState[]
		local spaces = {}
		local next_recent, next_titles = {}, {}
		local visible_app = ""
		for _, space in ipairs(snapshot.spaces) do
			if display and space.display == display then
				local present, focused_app = {}, nil
				-- The space's window IDs also account for sticky windows on multiple spaces.
				for _, id in ipairs(space.windows) do
					local window = windows[id]
					if window then
						present[#present + 1] = window.app
						if space["has-focus"] and window["has-focus"] then
							focused_app = window.app
						end
					end
				end

				local front_app = space["has-focus"] and snapshot.front_app ~= "" and snapshot.front_app or nil
				local apps = order_apps(recent[space.id] or {}, present, front_app or focused_app)
				next_recent[space.id] = apps
				local app = front_app or apps[1] or titles[space.id] or ""
				next_titles[space.id] = app
				if space["is-visible"] then
					visible_app = app
				end
				spaces[#spaces + 1] = {
					id = space.id,
					index = space.index,
					active = space["is-visible"] == true,
					apps = apps,
				}
			end
		end
		table.sort(spaces, by_index)
		recent, titles = next_recent, next_titles
		return { display = display, spaces = spaces, app = visible_app }
	end

	return model
end

return M
