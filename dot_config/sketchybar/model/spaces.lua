--- Build per-display space state from yabai snapshots without depending on SketchyBar.
local M = {}

--- @class SpaceBox
--- @field id integer Stable yabai space ID, independent of its displayed index.
--- @field index integer
--- @field active boolean
--- @field apps string[] Most recently focused first, with one entry per app.

--- @class SpacesSnapshot
--- @field displays table[]
--- @field spaces table[]
--- @field windows table[]
--- @field front_app string

--- @class SpacesState
--- @field display integer? Current arrangement index, nil when disconnected.
--- @field boxes SpaceBox[]
--- @field app string App title for this display's visible space.

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

--- Create independent recency and title caches for one bar instance.
--- @return { update: fun(snapshot: SpacesSnapshot, display_uuid: string): SpacesState }
function M.new()
	local recent, titles = {}, {}
	local model = {}

	--- Resolve the display by UUID and update its spaces, pruning departed space IDs.
	--- @param snapshot SpacesSnapshot
	--- @param display_uuid string
	--- @return SpacesState
	function model.update(snapshot, display_uuid)
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

		local boxes, next_recent, next_titles = {}, {}, {}
		local title = ""
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
					title = app
				end
				boxes[#boxes + 1] = {
					id = space.id,
					index = space.index,
					active = space["is-visible"] == true,
					apps = apps,
				}
			end
		end
		table.sort(boxes, function(a, b)
			return a.index < b.index
		end)
		recent, titles = next_recent, next_titles
		return { display = display, boxes = boxes, app = title }
	end

	return model
end

return M
