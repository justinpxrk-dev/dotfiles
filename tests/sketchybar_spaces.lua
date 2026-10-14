--- Focused checks for app recency and space identity; run from the repository root.
--- pnpm run test:sketchybar
package.path = "dot_config/sketchybar/?.lua;" .. package.path
local spaces_model = require("model.spaces")

--- Create two displays, duplicate app windows, and an empty internal space.
--- @return SpacesSnapshot
local function snapshot()
	return {
		displays = { { uuid = "internal", index = 1 }, { uuid = "external", index = 2 } },
		spaces = {
			{ id = 101, index = 1, display = 1, windows = { 1, 2, 3 }, ["is-visible"] = true, ["has-focus"] = true },
			{ id = 102, index = 2, display = 1, windows = {}, ["is-visible"] = false, ["has-focus"] = false },
			{ id = 201, index = 3, display = 2, windows = { 4 }, ["is-visible"] = true, ["has-focus"] = false },
		},
		windows = {
			{ id = 1, app = "Zen", ["has-focus"] = true },
			{ id = 2, app = "Zed", ["has-focus"] = false },
			{ id = 3, app = "Zen", ["has-focus"] = false },
			{ id = 4, app = "Finder", ["has-focus"] = false },
		},
		front_app = "Zen",
	}
end

--- Compare an app sequence with its expected recency order.
--- @param actual string[]
--- @param expected string
--- @return nil
local function expect_apps(actual, expected)
	assert(table.concat(actual, ",") == expected, table.concat(actual, ",") .. " ~= " .. expected)
end

-- Duplicate windows share one app entry; focus promotes it, new apps append, closed apps drop out.
do
	local model, input = spaces_model.new("internal"), snapshot()
	local state = model.update(input)
	assert(state.display == 1 and #state.spaces == 2)
	expect_apps(state.spaces[1].apps, "Zen,Zed")
	input.front_app = "Zed"
	expect_apps(model.update(input).spaces[1].apps, "Zed,Zen")
	input.front_app = ""
	input.spaces[1]["has-focus"] = false
	input.windows[5] = { id = 5, app = "Finder" }
	input.spaces[1].windows = { 1, 2, 3, 5 }
	expect_apps(model.update(input).spaces[1].apps, "Zed,Zen,Finder")
	input.spaces[1].windows = { 1, 3, 5 }
	expect_apps(model.update(input).spaces[1].apps, "Zen,Finder")
end

-- Renumbering preserves a space's recency and title; a new space at an old number starts fresh.
do
	local model, input = spaces_model.new("internal"), snapshot()
	input.front_app = "Zed"
	model.update(input)
	input.front_app = ""
	input.spaces[1]["has-focus"] = false
	input.spaces[1].index, input.spaces[2].index = 2, 1
	local state = model.update(input)
	assert(state.spaces[1].id == 102 and state.spaces[2].id == 101 and state.spaces[2].index == 2)
	expect_apps(state.spaces[2].apps, "Zed,Zen")
	input.spaces[1].windows = {}
	assert(model.update(input).app == "Zed")
	input.spaces[1]["is-visible"], input.spaces[2]["is-visible"] = false, true
	assert(model.update(input).app == "")
	input.spaces[1].id, input.spaces[1].windows = 303, { 1, 2, 3 }
	input.spaces[1]["is-visible"], input.spaces[2]["is-visible"] = true, false
	state = model.update(input)
	expect_apps(state.spaces[2].apps, "Zen,Zed")
	assert(state.app == "Zen")
end

print("App recency and space renumbering checks passed.")
