--- Regression tests for space state, region ordering, and asynchronous refreshes.
--- Run from the repository root with `lua tests/sketchybar.lua`.
package.path = "dot_config/sketchybar/?.lua;" .. package.path

local spaces_model = require("model.spaces")
local passed = 0

--- Run a case and include its name in any failure.
--- @param name string
--- @param run fun()
--- @return nil
local function test(name, run)
	local ok, err = xpcall(run, debug.traceback)
	assert(ok, name .. ": " .. tostring(err))
	passed = passed + 1
end

--- Compare an app sequence with an expected comma-separated order.
--- @param actual string[]
--- @param expected string
--- @return nil
local function expect_apps(actual, expected)
	assert(table.concat(actual, ",") == expected, table.concat(actual, ",") .. " ~= " .. expected)
end

--- Create a snapshot with duplicate app windows and an unrelated external display.
--- @return SpacesSnapshot
local function snapshot()
	return {
		displays = { { uuid = "built-in", index = 1 }, { uuid = "external", index = 2 } },
		spaces = {
			{ id = 101, index = 1, display = 1, windows = { 1, 2, 3 }, ["is-visible"] = true, ["has-focus"] = true },
			{ id = 102, index = 2, display = 1, windows = {}, ["is-visible"] = false, ["has-focus"] = false },
			{ id = 201, index = 3, display = 2, windows = { 4 }, ["is-visible"] = true, ["has-focus"] = false },
		},
		windows = {
			{ id = 1, app = "Zen", space = 1, display = 1, ["has-focus"] = true },
			{ id = 2, app = "Zed", space = 1, display = 1, ["has-focus"] = false },
			{ id = 3, app = "Zen", space = 1, display = 1, ["has-focus"] = false },
			{ id = 4, app = "Finder", space = 3, display = 2, ["has-focus"] = false },
		},
		front_app = "Zen",
	}
end

test("filter displays, sort spaces, and deduplicate apps", function()
	local input = snapshot()
	input.spaces[1], input.spaces[2] = input.spaces[2], input.spaces[1]
	local state = spaces_model.new().update(input, "built-in")
	assert(state.display == 1 and #state.boxes == 2 and state.boxes[1].index == 1)
	expect_apps(state.boxes[1].apps, "Zen,Zed")
	assert(state.app == "Zen" and state.boxes[1].active and not state.boxes[2].active)
end)

test("retain recency across space renumbering and remove closed apps", function()
	local model, input = spaces_model.new(), snapshot()
	input.front_app = "Zed"
	model.update(input, "built-in")
	input.front_app = ""
	input.spaces[1]["has-focus"] = false
	input.spaces[1].index, input.spaces[2].index = 2, 1
	expect_apps(model.update(input, "built-in").boxes[2].apps, "Zed,Zen")
	input.spaces[1].windows = { 1, 3 }
	expect_apps(model.update(input, "built-in").boxes[2].apps, "Zen")
end)

test("a newly created space does not inherit an old index's recency", function()
	local model, input = spaces_model.new(), snapshot()
	input.front_app = "Zed"
	model.update(input, "built-in")
	input.spaces[1].id = 303
	input.spaces[1]["has-focus"] = false
	input.front_app = ""
	expect_apps(model.update(input, "built-in").boxes[1].apps, "Zen,Zed")
end)

test("follow UUIDs when display indices swap and clear a disconnected display", function()
	local model, input = spaces_model.new(), snapshot()
	model.update(input, "built-in")
	input.displays[1].index, input.displays[2].index = 2, 1
	input.spaces[1].display, input.spaces[2].display, input.spaces[3].display = 2, 2, 1
	local state = model.update(input, "built-in")
	assert(state.display == 2 and state.boxes[1].id == 101 and #state.boxes == 2)
	input.displays = { input.displays[2] }
	state = model.update(input, "built-in")
	assert(state.display == nil and #state.boxes == 0 and state.app == "")
end)

test("a windowless front app names the pill even with a window on another display", function()
	local input = snapshot()
	input.front_app = "Finder"
	local state = spaces_model.new().update(input, "built-in")
	assert(state.app == "Finder")
	expect_apps(state.boxes[1].apps, "Zen,Zed")
end)

test("remember an empty space's app without leaking it into another space", function()
	local model, input = spaces_model.new(), snapshot()
	input.spaces[1].windows = {}
	input.front_app = "Finder"
	model.update(input, "built-in")
	input.spaces[1]["has-focus"] = false
	input.front_app = "Zen"
	assert(model.update(input, "built-in").app == "Finder")
	input.spaces[1]["is-visible"], input.spaces[2]["is-visible"] = false, true
	assert(model.update(input, "built-in").app == "")
end)

test("sticky windows appear in every space listing them", function()
	local input = snapshot()
	input.spaces[2].windows = { 1 }
	expect_apps(spaces_model.new().update(input, "built-in").boxes[2].apps, "Zen")
end)

local palette = 0
package.loaded["helpers.colorschemes"] = {
	--- Supply distinct palette roles so tests can detect incorrect color selection.
	--- @param active boolean
	--- @return table
	get_space_color_options = function(active)
		return {
			background = { color = 100 + palette, border_color = (active and 200 or 300) + palette },
			icon = { color = (active and 400 or 500) + palette },
			dim = { color = 600 + palette },
		}
	end,
	--- @return integer
	get_bar_background = function()
		return 700 + palette
	end,
	--- @return table
	get_default_color_options = function()
		return {}
	end,
	--- @return table
	get_now_playing_artwork_logo_color_options = function()
		return {}
	end,
	--- @param _playing boolean
	--- @return table
	get_now_playing_track_color_options = function(_playing)
		return {}
	end,
	--- @return table
	get_resources_graph_color_options = function()
		return {}
	end,
}
package.loaded["helpers.app_icons"] = {
	--- @param app string
	--- @return string
	lookup = function(app)
		return ":" .. app .. ":"
	end,
}

local merge = require("helpers.utils").merge
local fake = {}

--- Reset the recording SketchyBar implementation between renderer and event tests.
--- @return nil
local function reset_bar()
	fake.items, fake.order, fake.delays, fake.requests, fake.bars = {}, {}, {}, {}, {}
	fake.adds, fake.removes = 0, 0
end

--- Record adds and reject duplicate item names.
--- @param kind string
--- @param name string
--- @param options table
--- @param bracket_options table?
--- @return table
function fake.add(kind, name, options, bracket_options)
	assert(not fake.items[name], "duplicate add: " .. name)
	fake.items[name] = merge(bracket_options or options, { kind = kind })
	fake.order[#fake.order + 1] = name
	fake.adds = fake.adds + 1
	return {}
end

--- Record property changes and reject accidental re-positioning during updates.
--- @param name string
--- @param options table
--- @return nil
function fake.set(name, options)
	assert(fake.items[name], "set missing item: " .. name)
	assert(options.position == nil, "content update changed position")
	fake.items[name] = merge(options, fake.items[name])
end

--- Remove one known item from the creation order.
--- @param name string
--- @return nil
function fake.remove(name)
	assert(fake.items[name], "remove missing item: " .. name)
	fake.items[name] = nil
	fake.removes = fake.removes + 1
	for i, existing in ipairs(fake.order) do
		if existing == name then
			table.remove(fake.order, i)
			break
		end
	end
end

--- @param _seconds number
--- @param callback fun()
--- @return nil
function fake.delay(_seconds, callback)
	fake.delays[#fake.delays + 1] = callback
end

--- @param command string
--- @param callback fun(result: any, exit_code: integer)
--- @return nil
function fake.exec(command, callback)
	fake.requests[#fake.requests + 1] = { command = command, callback = callback }
end

--- @param options table
--- @return nil
function fake.bar(options)
	fake.bars[#fake.bars + 1] = options
end

reset_bar()
package.loaded["sketchybar"] = fake
local spaces_view = require("views.spaces")
local top_layout =
	{ display_uuid = "built-in", position = "e", left_position = "q", app_position = "q", apple_position = "left" }
local external_layout = { display_uuid = "external", position = "center", app_position = "center" }

--- Create independent boxes for structural tests.
--- @param count integer
--- @return SpaceBox[]
local function boxes(count)
	local result = {}
	for i = 1, count do
		result[i] = { id = 100 + i, index = i, apps = { "Zen", "Zed" }, active = i == 1 }
	end
	return result
end

--- Return an item's visual offset inside a region, reversing q's creation order.
--- @param name string
--- @param position string
--- @return integer
local function offset(name, position)
	local names = {}
	for _, candidate in ipairs(fake.order) do
		if fake.items[candidate].position == position then
			names[#names + 1] = candidate
		end
	end
	for i, candidate in ipairs(names) do
		if candidate == name then
			return position == "q" and (#names - i + 1) or i
		end
	end
	error("item absent from region: " .. name)
end

test("notch layout reads left to right and keeps the title outermost", function()
	reset_bar()
	local view = spaces_view.new(top_layout)
	view.update(boxes(5), "Zen")
	assert(offset("spaces.app_title.icon", "q") < offset("spaces.app_title.label", "q"))
	assert(offset("spaces.app_title.label", "q") < offset("spaces.1.num", "q"))
	assert(offset("spaces.1.num", "q") < offset("spaces.1.div", "q"))
	assert(offset("spaces.1.div", "q") < offset("spaces.1.g1", "q"))
	assert(offset("spaces.1.g1", "q") < offset("spaces.1.g2", "q"))
	assert(offset("spaces.1.num", "q") < offset("spaces.2.num", "q"))
	assert(offset("spaces.3.num", "e") < offset("spaces.5.num", "e"))
	assert(fake.items["spaces.app_title.apple"].position == "left")
end)

test("external title leads the centered spaces and omits the Apple badge", function()
	reset_bar()
	spaces_view.new(external_layout).update(boxes(3), "Zen")
	assert(offset("spaces.app_title.label", "center") < offset("spaces.1.num", "center"))
	assert(fake.items["spaces.app_title.apple"] == nil)
end)

test("content and theme updates retain items, colors, and geometry", function()
	reset_bar()
	local view = spaces_view.new(top_layout)
	view.update(boxes(3), "Zen")
	local adds, removes = fake.adds, fake.removes
	local changed = boxes(3)
	changed[1].apps = { "Zed", "Zen" }
	view.update(changed, "Zed")
	palette = 10
	view.repaint()
	assert(fake.adds == adds and fake.removes == removes)
	assert(fake.items["spaces.1.g1"].icon.string == ":Zed:")
	assert(fake.items["spaces.1.g1"].icon.color == 410 and fake.items["spaces.1.g2"].icon.color == 610)
	assert(fake.items["spaces.2.g1"].icon.color == 510 and fake.items["spaces.2.g2"].icon.color == 510)
	assert(fake.items["spaces.1.bracket"].background.border_color == 210)
	assert(fake.items["spaces.1.bracket"].background.height == 28)
	assert(fake.items["spaces.app_title.bracket"].background.color == 210)
	assert(fake.items["spaces.app_title.label"].label.color == 710)
	palette = 0
end)

test("app count changes rebuild cleanly and preserve title styling and order", function()
	reset_bar()
	local view = spaces_view.new(top_layout)
	view.update(boxes(3), "Zen")
	local changed = boxes(3)
	changed[1].apps = { "Zen" }
	view.update(changed, "Zen")
	assert(fake.items["spaces.1.g2"] == nil)
	assert(fake.items["spaces.app_title.label"].label.string == "Zen")
	assert(fake.items["spaces.app_title.bracket"].background.height == 28)
	assert(offset("spaces.app_title.icon", "q") < offset("spaces.1.num", "q"))
end)

test("empty spaces hide dividers and an unresolved title leaves no spacer", function()
	reset_bar()
	local view = spaces_view.new(top_layout)
	local empty = boxes(1)
	empty[1].apps = {}
	view.update(empty, "")
	view.repaint()
	assert(fake.items["spaces.1.div"].drawing == false)
	assert(fake.items["spaces.app_title.spacer"].drawing == false)
	assert(fake.items["spaces.app_title.bracket"].drawing == false)
	assert(fake.items["spaces.app_title.apple"].drawing ~= false)
	view.update({}, "")
	assert(fake.items["spaces.1.num"] == nil)
end)

--- Start an independent event handler with the real model and renderer.
--- @return table
local function handler()
	reset_bar()
	package.loaded["event.handlers.spaces"] = nil
	local events = require("event.handlers.spaces")
	events.setup(top_layout)
	return events
end

--- Fire the next scheduled debounce callback.
--- @return nil
local function tick()
	assert(#fake.delays > 0, "no scheduled refresh")
	table.remove(fake.delays, 1)()
end

--- Resolve a query batch in reverse callback order, optionally failing one query.
--- @param input SpacesSnapshot
--- @param failure string?
--- @return nil
local function reply(input, failure)
	local requests = fake.requests
	fake.requests = {}
	assert(#requests == 4, "expected one query batch")
	for i = #requests, 1, -1 do
		local request = requests[i]
		local key = request.command:match("%-%-(%w+)$") or "front_app"
		local result = input[key]
		if key == "front_app" then
			result = '"LSDisplayName"="' .. input.front_app .. '"\n'
		end
		if failure == "invalid_spaces" and key == "spaces" then
			result = "not JSON"
		end
		request.callback(result, failure == key and 1 or 0)
	end
end

test("signals during the debounce produce one query batch", function()
	local events = handler()
	for _ = 1, 10 do
		events.spaces_change_handler()
	end
	assert(#fake.delays == 1 and #fake.requests == 0)
	tick()
	reply(snapshot())
	assert(#fake.delays == 0 and #fake.requests == 0 and #fake.bars == 1)
end)

test("signals during a query request one non-overlapping follow-up", function()
	local events = handler()
	events.spaces_change_handler()
	tick()
	for _ = 1, 10 do
		events.spaces_change_handler()
	end
	assert(#fake.requests == 4 and #fake.delays == 0)
	reply(snapshot())
	assert(#fake.delays == 1 and #fake.bars == 0)
	tick()
	local input = snapshot()
	input.front_app = "Zed"
	reply(input)
	assert(fake.items["spaces.app_title.label"].label.string == "Zed")
	assert(#fake.delays == 0)
end)

test("failed or malformed yabai queries preserve the UI and allow recovery", function()
	local events = handler()
	events.spaces_change_handler()
	tick()
	reply(snapshot())
	local adds, removes = fake.adds, fake.removes
	for _, failure in ipairs({ "spaces", "windows", "displays", "invalid_spaces" }) do
		events.spaces_change_handler()
		tick()
		reply(snapshot(), failure)
		assert(fake.adds == adds and fake.removes == removes and #fake.bars == 1)
	end
	events.spaces_change_handler()
	tick()
	reply(snapshot())
	assert(#fake.bars == 2)
end)

test("front-app lookup failure is nonfatal and disconnect hides the bar", function()
	local events = handler()
	events.spaces_change_handler()
	tick()
	reply(snapshot(), "front_app")
	assert(#fake.bars == 1 and fake.bars[1].display == 1)
	events.spaces_change_handler()
	tick()
	local input = snapshot()
	input.displays = {}
	reply(input)
	assert(fake.bars[2].hidden == true and fake.items["spaces.1.num"] == nil)
end)

print(string.format("SketchyBar: %d regression tests passed", passed))
