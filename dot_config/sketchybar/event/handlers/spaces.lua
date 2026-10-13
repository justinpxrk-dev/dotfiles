--- Query yabai and serialize refreshes for one display's space indicators.
local sbar = require("sketchybar")
local model = require("model.spaces").new()
local spaces_view = require("views.spaces")

local M = {}
local DEBOUNCE = 0.05
local QUERIES = {
	displays = "yabai -m query --displays",
	spaces = "yabai -m query --spaces",
	windows = "yabai -m query --windows",
	front_app = 'lsappinfo info -only name "$(lsappinfo front)"',
}

local display_uuid, view
local scheduled, running, dirty = false, false, false

--- Collect parallel queries and complete once all callbacks arrive; a failed yabai query
--- leaves the current UI intact. Failure to resolve a windowless front app is nonfatal.
--- @param done fun(snapshot: SpacesSnapshot?)
--- @return nil
local function query_snapshot(done)
	local snapshot, remaining, valid = {}, 4, true
	for key, command in pairs(QUERIES) do
		sbar.exec(command, function(result, exit_code)
			if key == "front_app" then
				snapshot.front_app = exit_code == 0
						and type(result) == "string"
						and result:match('"LSDisplayName"%s*=%s*"(.-)"')
					or ""
			elseif exit_code == 0 and type(result) == "table" then
				snapshot[key] = result
			else
				valid = false
			end
			remaining = remaining - 1
			if remaining == 0 then
				done(valid and snapshot or nil)
			end
		end)
	end
end

--- Configure the display identity and create the renderer before subscribing to events.
--- @param config SpaceLayout
--- @return nil
function M.setup(config)
	display_uuid = config.display_uuid
	view = spaces_view.new(config)
end

--- Coalesce signals before a query; signals during a query request one subsequent refresh.
--- @return nil
function M.spaces_change_handler()
	if running then
		dirty = true
		return
	end
	if scheduled then
		return
	end
	scheduled = true
	sbar.delay(DEBOUNCE, function()
		scheduled, running, dirty = false, true, false
		query_snapshot(function(snapshot)
			-- A signal during collection can make the parallel query results disagree.
			if snapshot and not dirty then
				local state = model.update(snapshot, display_uuid)
				-- The bar and its space row must follow the same arrangement index.
				sbar.bar({ display = state.display, hidden = state.display == nil })
				view.update(state.boxes, state.app)
			end
			running = false
			if dirty then
				M.spaces_change_handler()
			end
		end)
	end)
end

--- Repaint cached content after the caller refreshes the theme palette.
--- @return nil
function M.theme_change_handler()
	if view then
		view.repaint()
	end
end

return M
