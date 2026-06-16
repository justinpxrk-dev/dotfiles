local sbar = require("sketchybar")

local item = require("constants.item")
local colorschemes = require("helpers.colorschemes")
local utils = require("helpers.utils")

local M = {}

M.PLAYING = false

--- Whether to color the pill from the always-dark palette (and use the dark-mode placeholder
--- logo), for the pinned-black top bar. Left false on the themed external bar; the requiring
--- profile sets it before the first event fires.
--- @type boolean
M.PIN_DARK_CHROME = false

local now_playing_track = "Not Playing"
local now_playing_artwork_path = "null"
local now_playing_inactive_artwork_path = "null"

function M.artwork_change_handler(env)
	local artwork_path = env.INFO.artwork_path
	local inactive_artwork_path = env.INFO.inactive_artwork_path

	now_playing_artwork_path = artwork_path
	now_playing_inactive_artwork_path = inactive_artwork_path

	local artwork_item_options = {
		background = {
			image = {
				string = M.PLAYING and now_playing_artwork_path or now_playing_inactive_artwork_path,
			},
		},
	}

	sbar.set(item.NOW_PLAYING.ARTWORK, artwork_item_options)
end

function M.theme_change_handler()
	local artwork_item_options = colorschemes.get_now_playing_artwork_logo_color_options(M.PIN_DARK_CHROME)
	local track_item_options = colorschemes.get_now_playing_track_color_options(M.PLAYING, M.PIN_DARK_CHROME)

	if now_playing_artwork_path == "null" then
		sbar.set(item.NOW_PLAYING.ARTWORK, artwork_item_options)
	end
	sbar.set(item.NOW_PLAYING.TRACK, track_item_options)
end

function M.pause_handler()
	M.PLAYING = false

	local artwork_item_options = now_playing_inactive_artwork_path ~= "null"
			and {
				background = {
					image = {
						string = now_playing_inactive_artwork_path,
					},
				},
			}
		or nil
	local track_item_options = colorschemes.get_now_playing_track_color_options(M.PLAYING, M.PIN_DARK_CHROME)

	sbar.set(item.NOW_PLAYING.ARTWORK, artwork_item_options)
	sbar.set(item.NOW_PLAYING.TRACK, track_item_options)
end

function M.stop_handler()
	M.PLAYING = false
	now_playing_track = "Not Playing"
	now_playing_artwork_path = "null"
	now_playing_inactive_artwork_path = "null"

	local artwork_item_options = colorschemes.get_now_playing_artwork_logo_color_options(M.PIN_DARK_CHROME)
	local track_item_options =
		utils.merge(colorschemes.get_now_playing_track_color_options(M.PLAYING, M.PIN_DARK_CHROME), {
			click_script = "",
			label = { string = now_playing_track },
		})

	sbar.set(item.NOW_PLAYING.ARTWORK, artwork_item_options)
	sbar.set(item.NOW_PLAYING.TRACK, track_item_options)
end

function M.unpause_handler()
	M.PLAYING = true

	local artwork_item_options = {
		background = {
			image = {
				string = now_playing_artwork_path,
			},
		},
	}
	local track_item_options = colorschemes.get_now_playing_track_color_options(M.PLAYING, M.PIN_DARK_CHROME)

	if now_playing_artwork_path ~= "null" then
		sbar.set(item.NOW_PLAYING.ARTWORK, artwork_item_options)
	end
	sbar.set(item.NOW_PLAYING.TRACK, track_item_options)
end

function M.track_change_handler(env)
	local playing = env.INFO.playing == "true" and true or false
	local artist = env.INFO.artist
	local bundle_identifier = env.INFO.bundle_identifier
	local title = env.INFO.title
	local track
	if artist ~= "null" and title ~= "null" then
		track = title .. " - " .. artist
	elseif title ~= "null" then
		track = title .. " - Unknown"
	elseif artist ~= "null" then
		track = "Unknown - " .. artist
	else
		track = "Unknown - Unknown"
	end

	M.PLAYING = playing
	now_playing_track = track

	local track_item_options =
		utils.merge(colorschemes.get_now_playing_track_color_options(M.PLAYING, M.PIN_DARK_CHROME), {
			label = {
				string = now_playing_track,
			},
		}, bundle_identifier ~= "null" and {
			click_script = string.format("open -b %s", bundle_identifier),
		} or {})

	sbar.set(item.NOW_PLAYING.TRACK, track_item_options)
end

return M
