--- Render outlined space boxes and solid app pills, including the reversed notch region.
local sbar = require("sketchybar")
local app_icons = require("helpers.app_icons")
local colorschemes = require("helpers.colorschemes")
local font = require("constants.font")
local item = require("constants.item")
local option = require("constants.option")
local utils = require("helpers.utils")

--- @class SpaceLayout
--- @field display_uuid string
--- @field position string
--- @field left_position string?
--- @field app_position string
--- @field apple_position string?

--- @class SpacePart
--- @field name string
--- @field options table

local M = {}
local EDGE_GAP, ICON_GAP = 10, 5

--- Compose the shared box geometry with a space or system pill's current colors.
--- @param colors table
--- @return table
local function bracket_options(colors)
	return utils.merge({ background = colors }, option.SPACES.BRACKET)
end

--- Return the solid accent fill used behind the Apple badge and app title.
--- @return table
local function pill_colors()
	local accent = colorschemes.get_space_color_options(true).background.border_color
	return { color = accent, border_color = accent }
end

--- Describe a space's items in visual left-to-right order, plus its bracket members.
--- @param box SpaceBox
--- @return SpacePart[], string[]
local function space_parts(box)
	local base = item.SPACES.PREFIX .. box.index
	local colors = colorschemes.get_space_color_options(box.active)
	local parts = {
		{ name = base .. ".spacer_l", options = option.SPACES.SPACER },
		{
			name = base .. ".num",
			options = utils.merge({
				padding_left = EDGE_GAP,
				padding_right = EDGE_GAP,
				icon = {
					string = tostring(box.index),
					color = colors.icon.color,
					font = box.active and font.DEFAULT.BOLD_LABEL or font.DEFAULT.ICON,
				},
			}, option.SPACES.NUM),
		},
		{
			name = base .. ".div",
			options = utils.merge({
				-- Item drawing collapses the divider even when setting its background color.
				drawing = #box.apps > 0,
				background = { color = colors.icon.color },
			}, option.SPACES.DIVIDER),
		},
	}
	local members = { base .. ".num", base .. ".div" }
	for i, app in ipairs(box.apps) do
		local name = base .. ".g" .. i
		parts[#parts + 1] = {
			name = name,
			options = utils.merge({
				padding_left = i == 1 and EDGE_GAP or ICON_GAP,
				padding_right = i == #box.apps and EDGE_GAP or 0,
				icon = {
					string = app_icons.lookup(app),
					color = (box.active and i > 1) and colors.dim.color or colors.icon.color,
				},
			}, option.SPACES.GLYPH),
		}
		members[#members + 1] = name
	end
	parts[#parts + 1] = { name = base .. ".spacer_r", options = option.SPACES.SPACER }
	return parts, members
end

--- Describe the title pill's content, hiding its spacer along with an unresolved title.
--- @param app string
--- @return SpacePart[]
local function title_parts(app)
	local shown = app ~= ""
	local color = colorschemes.get_bar_background()
	return {
		{
			name = item.SPACES.APP_ICON,
			options = utils.merge({
				drawing = shown,
				icon = { string = shown and app_icons.lookup(app) or "", color = color },
			}, option.SPACES.APP_ICON),
		},
		{
			name = item.SPACES.APP_TITLE,
			options = utils.merge(
				{ drawing = shown, label = { string = app, color = color } },
				option.SPACES.APP_TITLE
			),
		},
		{ name = item.SPACES.APP_SPACER, options = utils.merge({ drawing = shown }, option.SPACES.SPACER) },
	}
end

--- Add a sequence in region order; q grows leftward, so its visual sequence is reversed.
--- @param parts SpacePart[]
--- @param position string
--- @return nil
local function add_parts(parts, position)
	for i = 1, #parts do
		local part = parts[position == "q" and (#parts - i + 1) or i]
		sbar.add("item", part.name, utils.merge({ position = position }, part.options))
	end
end

--- Remove a cached box and exactly the items that were created for its app count.
--- @param box SpaceBox
--- @return nil
local function remove_box(box)
	sbar.remove(item.SPACES.PREFIX .. box.index .. ".bracket")
	for _, part in ipairs(space_parts(box)) do
		sbar.remove(part.name)
	end
end

--- Check whether additions or removals would change item order in either region.
--- @param previous SpaceBox[]
--- @param boxes SpaceBox[]
--- @return boolean
local function structure_changed(previous, boxes)
	if #previous ~= #boxes then
		return true
	end
	for i, box in ipairs(boxes) do
		if previous[i].index ~= box.index or #previous[i].apps ~= #box.apps then
			return true
		end
	end
	return false
end

--- Create a renderer with private cached content for structural and theme updates.
--- @param config SpaceLayout
--- @return { update: fun(boxes: SpaceBox[], app: string), repaint: fun() }
function M.new(config)
	local rendered, title = {}, ""
	local view = {}
	add_parts(title_parts(title), config.app_position)
	sbar.add("bracket", item.SPACES.APP_BRACKET, { item.SPACES.APP_ICON, item.SPACES.APP_TITLE }, {
		drawing = false,
		background = utils.merge(pill_colors(), option.SPACES.BRACKET.background),
	})
	if config.apple_position then
		sbar.add("item", item.SPACES.APPLE, utils.merge({ position = config.apple_position }, option.SPACES.APPLE))
		sbar.add(
			"item",
			item.SPACES.APPLE_SPACER,
			utils.merge({ position = config.apple_position }, option.SPACES.APPLE_SPACER)
		)
		sbar.add("bracket", item.SPACES.APPLE_BRACKET, { item.SPACES.APPLE }, bracket_options(pill_colors()))
	end

	--- Add or update a box, keeping add-only positioning out of content updates.
	--- @param box SpaceBox
	--- @param position string? Nil updates existing items in place.
	--- @return nil
	local function paint_box(box, position)
		local parts, members = space_parts(box)
		local background = bracket_options(colorschemes.get_space_color_options(box.active).background)
		local name = item.SPACES.PREFIX .. box.index .. ".bracket"
		if position then
			add_parts(parts, position)
			sbar.add("bracket", name, members, background)
		else
			for _, part in ipairs(parts) do
				sbar.set(part.name, part.options)
			end
			sbar.set(name, background)
		end
	end

	--- Paint content in one callback transaction, rebuilding only when item counts change.
	--- @param boxes SpaceBox[]
	--- @param app string
	--- @return nil
	function view.update(boxes, app)
		if structure_changed(rendered, boxes) then
			for _, box in ipairs(rendered) do
				remove_box(box)
			end
			local left_count = config.left_position and math.floor(#boxes / 2) or 0
			for i = left_count, 1, -1 do
				paint_box(boxes[i], config.left_position)
			end
			-- q appends leftward: re-add the title after the left spaces to keep it outermost.
			if config.left_position == config.app_position then
				sbar.remove(item.SPACES.APP_BRACKET)
				for _, part in ipairs(title_parts(title)) do
					sbar.remove(part.name)
				end
				add_parts(title_parts(app), config.app_position)
				sbar.add("bracket", item.SPACES.APP_BRACKET, { item.SPACES.APP_ICON, item.SPACES.APP_TITLE }, {})
			end
			for i = left_count + 1, #boxes do
				paint_box(boxes[i], config.position)
			end
		else
			for _, box in ipairs(boxes) do
				paint_box(box)
			end
		end
		for _, part in ipairs(title_parts(app)) do
			sbar.set(part.name, part.options)
		end
		sbar.set(item.SPACES.APP_BRACKET, utils.merge({ drawing = app ~= "" }, bracket_options(pill_colors())))
		if config.apple_position then
			sbar.set(item.SPACES.APPLE, { icon = { color = colorschemes.get_bar_background() } })
			sbar.set(item.SPACES.APPLE_BRACKET, bracket_options(pill_colors()))
		end
		rendered, title = boxes, app
	end

	--- Repaint the last rendered state using the caller's refreshed palette.
	--- @return nil
	function view.repaint()
		view.update(rendered, title)
	end

	view.repaint()
	return view
end

return M
